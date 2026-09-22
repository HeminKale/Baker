import { Hono } from "npm:hono";
import { zValidator } from "npm:@hono/zod-validator";
import { z } from "npm:zod";
import { and, asc, desc, eq, inArray, sql } from "npm:drizzle-orm";

import { authMiddleware, type AuthEnv } from "../middleware/auth.ts";
import { db } from "../lib/db.ts";
import { productImages, products, productVariants, projectItems, projects } from "../db/schema.ts";

export const projectsRoute = new Hono<AuthEnv>();

// Per-user, multi-list equivalent of Wishlist (07_projects.md). Every route
// here is strictly authed and scoped to the caller's own projects.
projectsRoute.use("/projects*", authMiddleware);

/** Loads a project's items joined to live variant/product/image data, plus
 *  server-computed totals (07_projects.md §8 -- "server is the source of
 *  truth for money", same rule discountEngine.ts follows for cart/checkout).
 *  Quantity discounts are deliberately NOT applied here -- §10 decision 3. */
async function loadProjectItems(projectId: string) {
  const rows = await db
    .select({
      id: projectItems.id,
      variantId: projectItems.variantId,
      quantity: projectItems.quantity,
      variantName: productVariants.name,
      currentPrice: productVariants.currentPrice,
      originalPrice: productVariants.originalPrice,
      stockQty: productVariants.stockQty,
      isActive: productVariants.isActive,
      productId: products.id,
      productName: products.name,
      addedAt: projectItems.addedAt,
    })
    .from(projectItems)
    .innerJoin(productVariants, eq(projectItems.variantId, productVariants.id))
    .innerJoin(products, eq(productVariants.productId, products.id))
    .where(eq(projectItems.projectId, projectId))
    .orderBy(asc(projectItems.addedAt));

  const productIds = [...new Set(rows.map((r) => r.productId))];
  const images = productIds.length
    ? await db
        .select()
        .from(productImages)
        .where(and(inArray(productImages.productId, productIds), eq(productImages.isPrimary, true)))
    : [];
  const imageByProduct = new Map(images.map((img) => [img.productId, img.publicUrl]));

  const items = rows.map((row) => ({ ...row, imageUrl: imageByProduct.get(row.productId) ?? null }));
  const estimatedTotal = items.reduce((sum, i) => sum + i.currentPrice * i.quantity, 0);
  const originalTotal = items.reduce((sum, i) => sum + i.originalPrice * i.quantity, 0);

  return { items, estimatedTotal, originalTotal };
}

/** Confirms `projectId` belongs to `userId`, returning the row or null. */
async function findOwnedProject(projectId: string, userId: string) {
  const [row] = await db
    .select()
    .from(projects)
    .where(and(eq(projects.id, projectId), eq(projects.userId, userId)))
    .limit(1);
  return row ?? null;
}

const listQuerySchema = z.object({
  status: z.enum(["active", "completed"]).optional(),
});

// List + item count + best-effort cover image + estimated total, for the
// Projects List screen (07_projects.md §5).
projectsRoute.get("/projects", zValidator("query", listQuerySchema), async (c) => {
  const authUser = c.get("user");
  const { status } = c.req.valid("query");

  const rows = await db
    .select()
    .from(projects)
    .where(
      status
        ? and(eq(projects.userId, authUser.id), eq(projects.status, status))
        : eq(projects.userId, authUser.id),
    )
    .orderBy(desc(projects.createdAt));

  const projectIds = rows.map((r) => r.id);
  const itemRows = projectIds.length
    ? await db
        .select({
          projectId: projectItems.projectId,
          quantity: projectItems.quantity,
          currentPrice: productVariants.currentPrice,
          productId: products.id,
          addedAt: projectItems.addedAt,
        })
        .from(projectItems)
        .innerJoin(productVariants, eq(projectItems.variantId, productVariants.id))
        .innerJoin(products, eq(productVariants.productId, products.id))
        .where(inArray(projectItems.projectId, projectIds))
    : [];

  const productIds = [...new Set(itemRows.map((r) => r.productId))];
  const images = productIds.length
    ? await db
        .select()
        .from(productImages)
        .where(and(inArray(productImages.productId, productIds), eq(productImages.isPrimary, true)))
    : [];
  const imageByProduct = new Map(images.map((img) => [img.productId, img.publicUrl]));

  const byProject = new Map<string, typeof itemRows>();
  for (const row of itemRows) {
    const list = byProject.get(row.projectId) ?? [];
    list.push(row);
    byProject.set(row.projectId, list);
  }

  const data = rows.map((project) => {
    const items = byProject.get(project.id) ?? [];
    const coverImageUrl = items.length
      ? (imageByProduct.get(items[0].productId) ?? null)
      : null;
    return {
      ...project,
      itemCount: items.length,
      estimatedTotal: items.reduce((sum, i) => sum + i.currentPrice * i.quantity, 0),
      coverImageUrl,
    };
  });

  return c.json({ data });
});

const createProjectSchema = z.object({
  name: z.string().trim().min(1).max(200),
  eventDate: z.coerce.date().optional(),
  clientName: z.string().trim().max(200).optional(),
  clientPhone: z.string().trim().max(30).optional(),
  notes: z.string().trim().max(2000).optional(),
});

projectsRoute.post("/projects", zValidator("json", createProjectSchema), async (c) => {
  const authUser = c.get("user");
  const body = c.req.valid("json");

  const [project] = await db
    .insert(projects)
    .values({ userId: authUser.id, ...body })
    .returning();

  return c.json({ data: { ...project, itemCount: 0, estimatedTotal: 0, coverImageUrl: null } }, 201);
});

// Flattened set of variantIds across all *active* projects (Add-to-Project
// icon's filled/outline state, §3/§9) -- must come before /projects/:id so
// "item-variant-ids" isn't parsed as a project id.
projectsRoute.get("/projects/item-variant-ids", async (c) => {
  const authUser = c.get("user");

  const rows = await db
    .select({ variantId: projectItems.variantId })
    .from(projectItems)
    .innerJoin(projects, eq(projectItems.projectId, projects.id))
    .where(and(eq(projects.userId, authUser.id), eq(projects.status, "active")));

  return c.json({ data: [...new Set(rows.map((r) => r.variantId))] });
});

// Which of the caller's *active* projects already contain this variant --
// backs the Add-to-Project dialog's per-row checkbox state (§4). Must come
// before /projects/:id so "item-membership" isn't parsed as a project id.
projectsRoute.get("/projects/item-membership/:variantId", async (c) => {
  const authUser = c.get("user");
  const variantId = c.req.param("variantId");

  const rows = await db
    .select({ projectId: projectItems.projectId })
    .from(projectItems)
    .innerJoin(projects, eq(projectItems.projectId, projects.id))
    .where(
      and(
        eq(projects.userId, authUser.id),
        eq(projects.status, "active"),
        eq(projectItems.variantId, variantId),
      ),
    );

  return c.json({ data: rows.map((r) => r.projectId) });
});

projectsRoute.get("/projects/:id", async (c) => {
  const authUser = c.get("user");
  const project = await findOwnedProject(c.req.param("id"), authUser.id);
  if (!project) {
    return c.json({ error: { code: "PROJECT_NOT_FOUND", message: "Project not found" } }, 404);
  }

  const { items, estimatedTotal, originalTotal } = await loadProjectItems(project.id);
  return c.json({ data: { ...project, items, estimatedTotal, originalTotal } });
});

const updateProjectSchema = z.object({
  name: z.string().trim().min(1).max(200).optional(),
  status: z.enum(["active", "completed"]).optional(),
  eventDate: z.coerce.date().nullable().optional(),
  clientName: z.string().trim().max(200).nullable().optional(),
  clientPhone: z.string().trim().max(30).nullable().optional(),
  notes: z.string().trim().max(2000).nullable().optional(),
});

// Rename / edit event-client details / mark complete / reopen (§6, §6b, §10
// decision 1) -- all share one PATCH, same shape as PATCH /cart/items/:id.
projectsRoute.patch("/projects/:id", zValidator("json", updateProjectSchema), async (c) => {
  const authUser = c.get("user");
  const project = await findOwnedProject(c.req.param("id"), authUser.id);
  if (!project) {
    return c.json({ error: { code: "PROJECT_NOT_FOUND", message: "Project not found" } }, 404);
  }
  const body = c.req.valid("json");

  const set: Record<string, unknown> = { ...body };
  if (body.status === "completed" && project.status !== "completed") {
    set.completedAt = new Date();
  } else if (body.status === "active" && project.status !== "active") {
    set.completedAt = null; // Reopen clears the completion timestamp.
  }

  const [updated] = await db.update(projects).set(set).where(eq(projects.id, project.id)).returning();
  const { items, estimatedTotal, originalTotal } = await loadProjectItems(project.id);
  return c.json({ data: { ...updated, items, estimatedTotal, originalTotal } });
});

// Delete project (§10 decision 2 -- direct icon tap, confirmation dialog is a
// client-side concern). Cascades to project_items via FK.
projectsRoute.delete("/projects/:id", async (c) => {
  const authUser = c.get("user");
  const project = await findOwnedProject(c.req.param("id"), authUser.id);
  if (!project) {
    return c.json({ error: { code: "PROJECT_NOT_FOUND", message: "Project not found" } }, 404);
  }

  await db.delete(projects).where(eq(projects.id, project.id));
  return c.json({ data: { ok: true } });
});

const addItemSchema = z.object({
  variantId: z.string().uuid(),
  quantity: z.coerce.number().int().min(1).default(1),
});

projectsRoute.post("/projects/:id/items", zValidator("json", addItemSchema), async (c) => {
  const authUser = c.get("user");
  const project = await findOwnedProject(c.req.param("id"), authUser.id);
  if (!project) {
    return c.json({ error: { code: "PROJECT_NOT_FOUND", message: "Project not found" } }, 404);
  }
  const { variantId, quantity } = c.req.valid("json");

  const [variant] = await db.select().from(productVariants).where(eq(productVariants.id, variantId)).limit(1);
  if (!variant) {
    return c.json({ error: { code: "VARIANT_NOT_FOUND", message: "Variant not found" } }, 404);
  }

  // Unlike cart, project quantities aren't stock-capped -- a project is a
  // plan of what's needed, which can exceed current stock (07_projects.md
  // §7's live-join note: it's a running plan, not a receipt).
  await db
    .insert(projectItems)
    .values({ projectId: project.id, variantId, quantity })
    .onConflictDoUpdate({
      target: [projectItems.projectId, projectItems.variantId],
      set: { quantity: sql`${projectItems.quantity} + ${quantity}` },
    });

  const { items, estimatedTotal, originalTotal } = await loadProjectItems(project.id);
  return c.json({ data: { ...project, items, estimatedTotal, originalTotal } }, 201);
});

const updateItemSchema = z.object({
  quantity: z.coerce.number().int().min(0),
});

projectsRoute.patch(
  "/projects/:id/items/:itemId",
  zValidator("json", updateItemSchema),
  async (c) => {
    const authUser = c.get("user");
    const project = await findOwnedProject(c.req.param("id"), authUser.id);
    if (!project) {
      return c.json({ error: { code: "PROJECT_NOT_FOUND", message: "Project not found" } }, 404);
    }
    const itemId = c.req.param("itemId");
    const { quantity } = c.req.valid("json");

    if (quantity === 0) {
      // Qty 0 = removal, matching cart's convention.
      await db
        .delete(projectItems)
        .where(and(eq(projectItems.id, itemId), eq(projectItems.projectId, project.id)));
    } else {
      await db
        .update(projectItems)
        .set({ quantity })
        .where(and(eq(projectItems.id, itemId), eq(projectItems.projectId, project.id)));
    }

    const { items, estimatedTotal, originalTotal } = await loadProjectItems(project.id);
    return c.json({ data: { ...project, items, estimatedTotal, originalTotal } });
  },
);

// Toggle-off from the Add-to-Project dialog (§4) doesn't have an item id
// handy (only the variantId it's rendering a checkbox for) -- mirrors
// wishlist's variant-keyed DELETE rather than making the client fetch the
// item id first just to toggle a checkbox.
projectsRoute.delete("/projects/:id/items/by-variant/:variantId", async (c) => {
  const authUser = c.get("user");
  const project = await findOwnedProject(c.req.param("id"), authUser.id);
  if (!project) {
    return c.json({ error: { code: "PROJECT_NOT_FOUND", message: "Project not found" } }, 404);
  }
  const variantId = c.req.param("variantId");

  await db
    .delete(projectItems)
    .where(and(eq(projectItems.projectId, project.id), eq(projectItems.variantId, variantId)));

  const { items, estimatedTotal, originalTotal } = await loadProjectItems(project.id);
  return c.json({ data: { ...project, items, estimatedTotal, originalTotal } });
});

projectsRoute.delete("/projects/:id/items/:itemId", async (c) => {
  const authUser = c.get("user");
  const project = await findOwnedProject(c.req.param("id"), authUser.id);
  if (!project) {
    return c.json({ error: { code: "PROJECT_NOT_FOUND", message: "Project not found" } }, 404);
  }
  const itemId = c.req.param("itemId");

  await db
    .delete(projectItems)
    .where(and(eq(projectItems.id, itemId), eq(projectItems.projectId, project.id)));

  const { items, estimatedTotal, originalTotal } = await loadProjectItems(project.id);
  return c.json({ data: { ...project, items, estimatedTotal, originalTotal } });
});

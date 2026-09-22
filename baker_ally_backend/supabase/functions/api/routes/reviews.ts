import { Hono } from "npm:hono";
import { zValidator } from "npm:@hono/zod-validator";
import { z } from "npm:zod";
import { and, desc, eq, sql } from "npm:drizzle-orm";

import { authMiddleware, type AuthEnv } from "../middleware/auth.ts";
import { db } from "../lib/db.ts";
import { orderItems, orders, productReviews, productVariants, users } from "../db/schema.ts";

export const reviewsRoute = new Hono<AuthEnv>();

// Product-level, verified-purchase-gated reviews (00_common_architecture.md
// §5a). The list endpoint is public (shown to guests on product detail);
// only eligibility and submit require login, so auth is applied per-route
// rather than blanket `.use()` like most other route files.

/** The caller's most recent delivered order_item for this product, if any --
 *  proof of eligibility and the FK target for a new review. `order_items`
 *  has no product_id column, only variant_id, so this joins out through
 *  product_variants. */
async function findEligibleOrderItem(userId: string, productId: string) {
  const [row] = await db
    .select({ id: orderItems.id })
    .from(orderItems)
    .innerJoin(orders, eq(orderItems.orderId, orders.id))
    .innerJoin(productVariants, eq(orderItems.variantId, productVariants.id))
    .where(
      and(
        eq(orders.userId, userId),
        eq(orders.status, "delivered"),
        eq(productVariants.productId, productId),
      ),
    )
    .orderBy(desc(orderItems.createdAt))
    .limit(1);
  return row ?? null;
}

async function hasAnyOrderItemForProduct(userId: string, productId: string) {
  const [row] = await db
    .select({ id: orderItems.id })
    .from(orderItems)
    .innerJoin(orders, eq(orderItems.orderId, orders.id))
    .innerJoin(productVariants, eq(orderItems.variantId, productVariants.id))
    .where(and(eq(orders.userId, userId), eq(productVariants.productId, productId)))
    .limit(1);
  return !!row;
}

const listReviewsSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(10),
});

reviewsRoute.get("/products/:id/reviews", zValidator("query", listReviewsSchema), async (c) => {
  const productId = c.req.param("id");
  const { page, limit } = c.req.valid("query");

  const [agg] = await db
    .select({
      reviewCount: sql<number>`count(*)::int`,
      overallAvg: sql<string | null>`avg(${productReviews.overallRating})`,
      qualityAvg: sql<string | null>`avg(${productReviews.qualityRating})`,
      valueAvg: sql<string | null>`avg(${productReviews.valueRating})`,
      packagingAvg: sql<string | null>`avg(${productReviews.packagingRating})`,
      accuracyAvg: sql<string | null>`avg(${productReviews.accuracyRating})`,
    })
    .from(productReviews)
    .where(eq(productReviews.productId, productId));

  const rows = await db
    .select({
      id: productReviews.id,
      overallRating: productReviews.overallRating,
      qualityRating: productReviews.qualityRating,
      valueRating: productReviews.valueRating,
      packagingRating: productReviews.packagingRating,
      accuracyRating: productReviews.accuracyRating,
      comment: productReviews.comment,
      tags: productReviews.tags,
      createdAt: productReviews.createdAt,
      userFullName: users.fullName,
    })
    .from(productReviews)
    .innerJoin(users, eq(productReviews.userId, users.id))
    .where(eq(productReviews.productId, productId))
    .orderBy(desc(productReviews.createdAt))
    .limit(limit)
    .offset((page - 1) * limit);

  const toNumOrNull = (v: string | null) => (v === null ? null : Number(v));

  return c.json({
    data: {
      summary: {
        overallRating: toNumOrNull(agg.overallAvg) ?? 0,
        reviewCount: agg.reviewCount,
        categoryAverages: {
          quality: toNumOrNull(agg.qualityAvg),
          value: toNumOrNull(agg.valueAvg),
          packaging: toNumOrNull(agg.packagingAvg),
          accuracy: toNumOrNull(agg.accuracyAvg),
        },
      },
      reviews: rows,
    },
  });
});

reviewsRoute.get("/products/:id/reviews/eligibility", authMiddleware, async (c) => {
  const authUser = c.get("user");
  const productId = c.req.param("id");

  const [existing] = await db
    .select({ id: productReviews.id })
    .from(productReviews)
    .where(and(eq(productReviews.userId, authUser.id), eq(productReviews.productId, productId)))
    .limit(1);
  if (existing) {
    return c.json({ data: { canReview: false, reason: "already_reviewed" } });
  }

  const orderItem = await findEligibleOrderItem(authUser.id, productId);
  if (orderItem) {
    return c.json({ data: { canReview: true } });
  }

  const purchased = await hasAnyOrderItemForProduct(authUser.id, productId);
  return c.json({ data: { canReview: false, reason: purchased ? "not_delivered" : "not_purchased" } });
});

const submitReviewSchema = z.object({
  overallRating: z.coerce.number().int().min(1).max(5),
  qualityRating: z.coerce.number().int().min(1).max(5).optional(),
  valueRating: z.coerce.number().int().min(1).max(5).optional(),
  packagingRating: z.coerce.number().int().min(1).max(5).optional(),
  accuracyRating: z.coerce.number().int().min(1).max(5).optional(),
  comment: z.string().trim().max(2000).optional(),
  tags: z.array(z.string().trim().min(1).max(40)).max(10).optional(),
});

// The plan's request shape includes a client-supplied `orderItemId`, but
// since eligibility is entirely server-computed anyway ("backend re-verifies
// eligibility server-side, never trusts the client" -- 00_common_architecture.md
// §5a), the server resolves the eligible order_item itself here rather than
// trusting a client-supplied id for a FK it doesn't otherwise validate.
reviewsRoute.post(
  "/products/:id/reviews",
  authMiddleware,
  zValidator("json", submitReviewSchema),
  async (c) => {
    const authUser = c.get("user");
    const productId = c.req.param("id");
    const body = c.req.valid("json");

    const [existing] = await db
      .select({ id: productReviews.id })
      .from(productReviews)
      .where(and(eq(productReviews.userId, authUser.id), eq(productReviews.productId, productId)))
      .limit(1);
    if (existing) {
      return c.json({ error: { code: "ALREADY_REVIEWED", message: "You already reviewed this product" } }, 409);
    }

    const orderItem = await findEligibleOrderItem(authUser.id, productId);
    if (!orderItem) {
      return c.json(
        { error: { code: "NOT_ELIGIBLE", message: "No delivered purchase found for this product" } },
        403,
      );
    }

    const [review] = await db
      .insert(productReviews)
      .values({ productId, userId: authUser.id, orderItemId: orderItem.id, ...body })
      .returning();

    return c.json({ data: review }, 201);
  },
);

import { boolean, integer, jsonb, pgTable, text, timestamp, uuid } from "npm:drizzle-orm/pg-core";

// Mirrors migrations/001-005 -- see those files for constraints/comments
// this schema doesn't repeat (RLS, FK-only indexes, etc).

export const roles = pgTable("roles", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull().unique(),
  privilegeLevelId: uuid("privilege_level_id"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

export const privilegeLevels = pgTable("privilege_levels", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull(),
  description: text("description"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

export const privilegeLevelPermissions = pgTable("privilege_level_permissions", {
  id: uuid("id").primaryKey().defaultRandom(),
  privilegeLevelId: uuid("privilege_level_id")
    .notNull()
    .references(() => privilegeLevels.id, { onDelete: "cascade" }),
  objectName: text("object_name").notNull(),
  canRead: boolean("can_read").notNull().default(false),
  canEdit: boolean("can_edit").notNull().default(false),
  fieldOverrides: jsonb("field_overrides"),
  recordScope: text("record_scope").notNull().default("own"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

export const users = pgTable("users", {
  // No default -- always set explicitly to the matching auth.users id.
  id: uuid("id").primaryKey(),
  email: text("email"),
  phone: text("phone"),
  fullName: text("full_name"),
  businessName: text("business_name"),
  gstin: text("gstin"),
  avatarUrl: text("avatar_url"),
  fcmToken: text("fcm_token"),
  roleId: uuid("role_id")
    .notNull()
    .references(() => roles.id),
  privilegeLevelId: uuid("privilege_level_id").references(() => privilegeLevels.id),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

export const addresses = pgTable("addresses", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id")
    .notNull()
    .references(() => users.id, { onDelete: "cascade" }),
  label: text("label"),
  line1: text("line1").notNull(),
  line2: text("line2"),
  city: text("city").notNull(),
  state: text("state").notNull(),
  pincode: text("pincode").notNull(),
  isDefault: boolean("is_default").notNull().default(false),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

// Mirrors migrations/007-012 -- catalog + wishlist (Milestone 2 / Phase 2).
// `products.search_vector` (a GENERATED ALWAYS tsvector column) is
// deliberately not mapped here -- nothing ever inserts/selects it as a typed
// value, routes/catalog.ts references it via a raw `sql` fragment instead.

export const categories = pgTable("categories", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull(),
  imageUrl: text("image_url"),
  sortOrder: integer("sort_order").notNull().default(0),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

export const subCategories = pgTable("sub_categories", {
  id: uuid("id").primaryKey().defaultRandom(),
  categoryId: uuid("category_id")
    .notNull()
    .references(() => categories.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  imageUrl: text("image_url"),
  sortOrder: integer("sort_order").notNull().default(0),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

export const products = pgTable("products", {
  id: uuid("id").primaryKey().defaultRandom(),
  subCategoryId: uuid("sub_category_id")
    .notNull()
    .references(() => subCategories.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  description: text("description"),
  isActive: boolean("is_active").notNull().default(true),
  isTrending: boolean("is_trending").notNull().default(false),
  sortOrder: integer("sort_order").notNull().default(0),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
});

export const productVariants = pgTable("product_variants", {
  id: uuid("id").primaryKey().defaultRandom(),
  productId: uuid("product_id")
    .notNull()
    .references(() => products.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  sku: text("sku").notNull().unique(),
  originalPrice: integer("original_price").notNull(),
  currentPrice: integer("current_price").notNull(),
  stockQty: integer("stock_qty").notNull().default(0),
  isActive: boolean("is_active").notNull().default(true),
  sortOrder: integer("sort_order").notNull().default(0),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

export const productImages = pgTable("product_images", {
  id: uuid("id").primaryKey().defaultRandom(),
  productId: uuid("product_id")
    .notNull()
    .references(() => products.id, { onDelete: "cascade" }),
  variantId: uuid("variant_id").references(() => productVariants.id, { onDelete: "cascade" }),
  storagePath: text("storage_path").notNull(),
  publicUrl: text("public_url").notNull(),
  sortOrder: integer("sort_order").notNull().default(0),
  isPrimary: boolean("is_primary").notNull().default(false),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

export const wishlists = pgTable("wishlists", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id")
    .notNull()
    .references(() => users.id, { onDelete: "cascade" }),
  variantId: uuid("variant_id")
    .notNull()
    .references(() => productVariants.id, { onDelete: "cascade" }),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

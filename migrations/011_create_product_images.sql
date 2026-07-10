-- Milestone 2 / Phase 2: product_images table
-- 00_common_architecture.md §4/§7 -- variant_id nullable: NULL means the image
-- applies to all variants of the product (shared primary/gallery shots).

CREATE TABLE IF NOT EXISTS product_images (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id    UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  variant_id    UUID REFERENCES product_variants(id) ON DELETE CASCADE,
  storage_path  TEXT NOT NULL,
  public_url    TEXT NOT NULL,
  sort_order    INTEGER NOT NULL DEFAULT 0,
  is_primary    BOOLEAN NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_product_images_product
  ON product_images(product_id);

ALTER TABLE product_images ENABLE ROW LEVEL SECURITY;

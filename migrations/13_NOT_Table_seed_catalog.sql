-- Milestone 2 / Phase 2: catalog seed data
--
-- Seeds all 6 categories + all 27 subcategories from the locked list in
-- 00_common_architecture.md §5, with 4 products per subcategory (2 = ~104
-- products), each with 3 variants and 2 images. "Festive Packaging" is
-- deliberately left with zero products to exercise the "Coming soon" empty
-- state (02_catalog_tab.md §8).
--
-- This is a LEAN seed, not the full 20-30-products-per-category volume from
-- the original brief -- see Milestone readme/Milestone 2.md for the decision
-- and for how to seed more later (append another file in this same shape,
-- or use the Milestone 6 admin panel once it exists -- nothing here is
-- hardcoded into the app).
--
-- Images are deterministic placeholder URLs (picsum.photos/seed/<slug>) --
-- swap for real Supabase Storage uploads once real product photography and
-- the admin panel exist.
--
-- Intended to run ONCE against a fresh catalog (no unique constraint on
-- categories/sub_categories/products.name -- re-running duplicates rows).
--
-- NOTE: an earlier version of this file used a separate `CREATE TEMP TABLE`
-- + `DO` block. Temp tables only exist within the session that created
-- them -- some SQL clients/connection poolers open a new connection per
-- statement, which surfaces as `ERROR: 42P01: relation "_seed_products"
-- does not exist` on the DO block even though the CREATE TEMP TABLE
-- statement itself succeeded. Fixed by inlining the product data directly
-- into the DO block's loop below, so the whole seed is one atomic
-- statement with no cross-statement state to lose.

BEGIN;

-- 1. Categories --------------------------------------------------------
INSERT INTO categories (name, image_url, sort_order) VALUES
  ('Ingredients', 'https://picsum.photos/seed/cat-ingredients/400', 1),
  ('Packaging', 'https://picsum.photos/seed/cat-packaging/400', 2),
  ('Tools & Equipment', 'https://picsum.photos/seed/cat-tools/400', 3),
  ('Cake Decorations', 'https://picsum.photos/seed/cat-decorations/400', 4),
  ('Seasonal & New Collections', 'https://picsum.photos/seed/cat-seasonal/400', 5),
  ('Bakeware', 'https://picsum.photos/seed/cat-bakeware/400', 6);

-- 2. Sub-categories ------------------------------------------------------
INSERT INTO sub_categories (category_id, name, image_url, sort_order) VALUES
  ((SELECT id FROM categories WHERE name = 'Ingredients'), 'Creams', 'https://picsum.photos/seed/sub-creams/400', 1),
  ((SELECT id FROM categories WHERE name = 'Ingredients'), 'Cocoa & Chocolates', 'https://picsum.photos/seed/sub-cocoa/400', 2),
  ((SELECT id FROM categories WHERE name = 'Ingredients'), 'Fruit Fillings & Crushes', 'https://picsum.photos/seed/sub-fruit/400', 3),
  ((SELECT id FROM categories WHERE name = 'Ingredients'), 'Food Stabilizers & Leaving Agents', 'https://picsum.photos/seed/sub-stabilizers/400', 4),
  ((SELECT id FROM categories WHERE name = 'Ingredients'), 'Mixes', 'https://picsum.photos/seed/sub-mixes/400', 5),
  ((SELECT id FROM categories WHERE name = 'Ingredients'), 'Food Colours', 'https://picsum.photos/seed/sub-colours/400', 6),
  ((SELECT id FROM categories WHERE name = 'Ingredients'), 'Food Flavours', 'https://picsum.photos/seed/sub-flavours/400', 7),

  ((SELECT id FROM categories WHERE name = 'Packaging'), 'Cake Boxes & Bases', 'https://picsum.photos/seed/sub-cakeboxes/400', 1),
  ((SELECT id FROM categories WHERE name = 'Packaging'), 'Dessert Boxes', 'https://picsum.photos/seed/sub-dessertboxes/400', 2),
  ((SELECT id FROM categories WHERE name = 'Packaging'), 'PVC & Acrylic Packaging', 'https://picsum.photos/seed/sub-pvc/400', 3),
  ((SELECT id FROM categories WHERE name = 'Packaging'), 'Biodegradable Packaging', 'https://picsum.photos/seed/sub-biodegradable/400', 4),
  ((SELECT id FROM categories WHERE name = 'Packaging'), 'Bags & Pouches', 'https://picsum.photos/seed/sub-bags/400', 5),
  ((SELECT id FROM categories WHERE name = 'Packaging'), 'Add-ons', 'https://picsum.photos/seed/sub-packaging-addons/400', 6),
  ((SELECT id FROM categories WHERE name = 'Packaging'), 'Festive Packaging', 'https://picsum.photos/seed/sub-festive-packaging/400', 7),

  ((SELECT id FROM categories WHERE name = 'Tools & Equipment'), 'Speciality Tools', 'https://picsum.photos/seed/sub-specialitytools/400', 1),
  ((SELECT id FROM categories WHERE name = 'Tools & Equipment'), 'Kitchen Appliances', 'https://picsum.photos/seed/sub-appliances/400', 2),
  ((SELECT id FROM categories WHERE name = 'Tools & Equipment'), 'Structure Tools', 'https://picsum.photos/seed/sub-structuretools/400', 3),

  ((SELECT id FROM categories WHERE name = 'Cake Decorations'), 'Edible Decorations', 'https://picsum.photos/seed/sub-edibledecor/400', 1),
  ((SELECT id FROM categories WHERE name = 'Cake Decorations'), 'Non Edible Decorations', 'https://picsum.photos/seed/sub-nonedibledecor/400', 2),
  ((SELECT id FROM categories WHERE name = 'Cake Decorations'), 'Add-ons', 'https://picsum.photos/seed/sub-decor-addons/400', 3),

  ((SELECT id FROM categories WHERE name = 'Seasonal & New Collections'), 'Collections for Festives', 'https://picsum.photos/seed/sub-festivecollections/400', 1),
  ((SELECT id FROM categories WHERE name = 'Seasonal & New Collections'), 'Stock Clearance Items', 'https://picsum.photos/seed/sub-clearance/400', 2),
  ((SELECT id FROM categories WHERE name = 'Seasonal & New Collections'), 'New Arrivals', 'https://picsum.photos/seed/sub-newarrivals/400', 3),

  ((SELECT id FROM categories WHERE name = 'Bakeware'), 'Cake Moulds', 'https://picsum.photos/seed/sub-cakemoulds/400', 1),
  ((SELECT id FROM categories WHERE name = 'Bakeware'), 'Dessert Moulds', 'https://picsum.photos/seed/sub-dessertmoulds/400', 2),
  ((SELECT id FROM categories WHERE name = 'Bakeware'), 'Paper Moulds', 'https://picsum.photos/seed/sub-papermoulds/400', 3),
  ((SELECT id FROM categories WHERE name = 'Bakeware'), 'Silicon Moulds', 'https://picsum.photos/seed/sub-siliconmoulds/400', 4);

-- 3. Expand product rows into products, variants and images -----------------
-- One row per product in the VALUES list below. variants[] and base_price
-- (paise, smallest variant) are expanded into 3 real product_variants rows
-- using multipliers [1, 1.9, 3.4] to approximate bulk/size pricing.
DO $$
DECLARE
  rec RECORD;
  idx INTEGER := 0;
  new_product_id UUID;
  new_variant_id UUID;
  v_index INTEGER;
  v_name TEXT;
  v_price INTEGER;
  v_stock INTEGER;
  v_is_trending BOOLEAN;
  v_created_at TIMESTAMPTZ;
  v_sale_factor NUMERIC;
  multipliers NUMERIC[] := ARRAY[1, 1.9, 3.4];
BEGIN
  FOR rec IN
    SELECT * FROM (VALUES
    -- Ingredients > Creams
    ('Ingredients', 'Creams', 'Fresh Cream 25% Fat', 'Rich dairy cream for whipping, ganache and mousse.', ARRAY['200ml','500ml','1L'], 4000, 'prod-freshcream'),
    ('Ingredients', 'Creams', 'Whipping Cream Non-Dairy', 'Stable non-dairy whipped topping for cakes and pastries.', ARRAY['200ml','500ml','1L'], 3200, 'prod-whipcream'),
    ('Ingredients', 'Creams', 'Mascarpone Cream Cheese', 'Creamy Italian cheese base for tiramisu and frostings.', ARRAY['250g','500g','1kg'], 9000, 'prod-mascarpone'),
    ('Ingredients', 'Creams', 'Ganache Base Cream', 'High-fat cream formulated for smooth glossy ganache.', ARRAY['200ml','500ml','1L'], 5500, 'prod-ganachecream'),
    -- Ingredients > Cocoa & Chocolates
    ('Ingredients', 'Cocoa & Chocolates', 'Dark Couverture Chocolate 55%', 'Premium dark couverture for enrobing and moulding.', ARRAY['250g','500g','1kg'], 25000, 'prod-darkcouverture'),
    ('Ingredients', 'Cocoa & Chocolates', 'Milk Compound Chocolate', 'Easy-melt compound chocolate for coating and dipping.', ARRAY['250g','500g','1kg'], 15000, 'prod-milkcompound'),
    ('Ingredients', 'Cocoa & Chocolates', 'Cocoa Powder Unsweetened', 'Deep-roasted cocoa powder for baking and dusting.', ARRAY['100g','250g','500g'], 8000, 'prod-cocoapowder'),
    ('Ingredients', 'Cocoa & Chocolates', 'White Chocolate Callets', 'Smooth white chocolate callets for moulding and drizzles.', ARRAY['250g','500g','1kg'], 27000, 'prod-whitechoc'),
    -- Ingredients > Fruit Fillings & Crushes
    ('Ingredients', 'Fruit Fillings & Crushes', 'Strawberry Fruit Filling', 'Sweet-tart strawberry filling for cakes and pastries.', ARRAY['250g','500g','1kg'], 9000, 'prod-strawberryfilling'),
    ('Ingredients', 'Fruit Fillings & Crushes', 'Mango Pulp Crush', 'Ripe mango pulp crush for mousses and fillings.', ARRAY['250g','500g','1kg'], 7500, 'prod-mangopulp'),
    ('Ingredients', 'Fruit Fillings & Crushes', 'Mixed Berry Compote', 'Tangy mixed berry compote for layering and glazing.', ARRAY['250g','500g','1kg'], 11000, 'prod-berrycompote'),
    ('Ingredients', 'Fruit Fillings & Crushes', 'Blueberry Filling', 'Thick blueberry filling for pies and cheesecakes.', ARRAY['250g','500g','1kg'], 12000, 'prod-blueberryfilling'),
    -- Ingredients > Food Stabilizers & Leaving Agents
    ('Ingredients', 'Food Stabilizers & Leaving Agents', 'Baking Powder Double Acting', 'Reliable double-acting leavening for consistent rise.', ARRAY['100g','250g','500g'], 4000, 'prod-bakingpowder'),
    ('Ingredients', 'Food Stabilizers & Leaving Agents', 'Gelatin Sheets (Bronze)', 'Bronze-grade gelatin sheets for mousses and glazes.', ARRAY['100g','250g','500g'], 9000, 'prod-gelatinsheets'),
    ('Ingredients', 'Food Stabilizers & Leaving Agents', 'Whipped Cream Stabilizer', 'Keeps whipped cream firm and glossy for hours.', ARRAY['100g','250g','500g'], 5000, 'prod-whipstabilizer'),
    ('Ingredients', 'Food Stabilizers & Leaving Agents', 'Instant Dry Yeast', 'Fast-acting instant yeast for breads and buns.', ARRAY['100g','250g','500g'], 4500, 'prod-instantyeast'),
    -- Ingredients > Mixes
    ('Ingredients', 'Mixes', 'Vanilla Sponge Premix', 'One-step vanilla sponge premix for a consistent crumb.', ARRAY['500g','1kg','5kg'], 15000, 'prod-vanillapremix'),
    ('Ingredients', 'Mixes', 'Chocolate Cake Premix', 'Rich cocoa premix for moist chocolate sponges.', ARRAY['500g','1kg','5kg'], 16000, 'prod-chocopremix'),
    ('Ingredients', 'Mixes', 'Red Velvet Premix', 'Classic red velvet premix with balanced cocoa notes.', ARRAY['500g','1kg','5kg'], 18000, 'prod-redvelvetpremix'),
    ('Ingredients', 'Mixes', 'Brownie Mix', 'Fudgy brownie mix, just add eggs, oil and water.', ARRAY['500g','1kg','5kg'], 14000, 'prod-browniemix'),
    -- Ingredients > Food Colours
    ('Ingredients', 'Food Colours', 'Gel Food Colour - Red', 'Concentrated gel colour, vivid red with no bleed.', ARRAY['20g','50g','100g'], 6000, 'prod-gelcolourred'),
    ('Ingredients', 'Food Colours', 'Gel Food Colour - Blue', 'Concentrated gel colour, deep royal blue.', ARRAY['20g','50g','100g'], 6000, 'prod-gelcolourblue'),
    ('Ingredients', 'Food Colours', 'Powder Food Colour - Gold', 'Shimmering edible gold powder for accents.', ARRAY['10g','25g','50g'], 9000, 'prod-powdercolourgold'),
    ('Ingredients', 'Food Colours', 'Rainbow Colour Kit', 'Six-colour gel kit covering the essential palette.', ARRAY['6x10g','6x25g','6x50g'], 15000, 'prod-rainbowkit'),
    -- Ingredients > Food Flavours
    ('Ingredients', 'Food Flavours', 'Vanilla Essence', 'Classic vanilla essence for batters and creams.', ARRAY['30ml','100ml','500ml'], 3500, 'prod-vanillaessence'),
    ('Ingredients', 'Food Flavours', 'Pineapple Flavour', 'Fruity pineapple flavouring for sponges and syrups.', ARRAY['30ml','100ml','500ml'], 3500, 'prod-pineappleflavour'),
    ('Ingredients', 'Food Flavours', 'Butterscotch Flavour', 'Warm butterscotch flavour for cakes and mousses.', ARRAY['30ml','100ml','500ml'], 4000, 'prod-butterscotchflavour'),
    ('Ingredients', 'Food Flavours', 'Rose Flavour Concentrate', 'Delicate rose flavour for festive sweets and cakes.', ARRAY['30ml','100ml','500ml'], 4500, 'prod-roseflavour'),
    -- Packaging > Cake Boxes & Bases
    ('Packaging', 'Cake Boxes & Bases', 'Plain Cake Box 8 inch', 'Sturdy plain white cake box, 8 inch.', ARRAY['Pack of 10','Pack of 25','Pack of 50'], 25000, 'prod-plaincakebox8'),
    ('Packaging', 'Cake Boxes & Bases', 'Cake Board Round 10 inch', 'Rigid round cake board, food-safe coating.', ARRAY['Pack of 10','Pack of 25','Pack of 50'], 18000, 'prod-cakeboardround10'),
    ('Packaging', 'Cake Boxes & Bases', 'Window Cake Box', 'Cake box with a clear display window on top.', ARRAY['Pack of 10','Pack of 25','Pack of 50'], 32000, 'prod-windowcakebox'),
    ('Packaging', 'Cake Boxes & Bases', 'Cake Drum Base Square', 'Thick square drum base for tiered cakes.', ARRAY['Pack of 10','Pack of 25','Pack of 50'], 22000, 'prod-cakedrumsquare'),
    -- Packaging > Dessert Boxes
    ('Packaging', 'Dessert Boxes', 'Pastry Box Small', 'Compact box for pastries and small desserts.', ARRAY['Pack of 10','Pack of 25','Pack of 50'], 12000, 'prod-pastryboxsmall'),
    ('Packaging', 'Dessert Boxes', 'Cupcake Box 6-Cavity', 'Insert-fitted box holding 6 cupcakes securely.', ARRAY['Pack of 10','Pack of 25','Pack of 50'], 15000, 'prod-cupcakebox6'),
    ('Packaging', 'Dessert Boxes', 'Macaron Box', 'Snug-fit box for a dozen macarons.', ARRAY['Pack of 10','Pack of 25','Pack of 50'], 14000, 'prod-macaronbox'),
    ('Packaging', 'Dessert Boxes', 'Dessert Cup with Lid', 'Clear cups with lids for mousse and parfaits.', ARRAY['Pack of 10','Pack of 25','Pack of 50'], 9000, 'prod-dessertcuplid'),
    -- Packaging > PVC & Acrylic Packaging
    ('Packaging', 'PVC & Acrylic Packaging', 'PVC Cake Box Transparent', 'Fully transparent PVC box for showcasing cakes.', ARRAY['Pack of 10','Pack of 25','Pack of 50'], 28000, 'prod-pvccakebox'),
    ('Packaging', 'PVC & Acrylic Packaging', 'Acrylic Cake Stand Round', 'Reusable acrylic display stand, round.', ARRAY['Small','Medium','Large'], 60000, 'prod-acryliccakestand'),
    ('Packaging', 'PVC & Acrylic Packaging', 'Acrylic Display Dome', 'Clear dome cover for display cakes.', ARRAY['Small','Medium','Large'], 45000, 'prod-acrylicdome'),
    ('Packaging', 'PVC & Acrylic Packaging', 'PVC Cupcake Insert Tray', 'PVC tray insert to hold cupcakes upright.', ARRAY['Pack of 10','Pack of 25','Pack of 50'], 9000, 'prod-pvccupcaketray'),
    -- Packaging > Biodegradable Packaging
    ('Packaging', 'Biodegradable Packaging', 'Kraft Paper Cake Box', 'Eco-friendly kraft paper box, sturdy and compostable.', ARRAY['Pack of 10','Pack of 25','Pack of 50'], 26000, 'prod-kraftcakebox'),
    ('Packaging', 'Biodegradable Packaging', 'Bagasse Dessert Tray', 'Sugarcane-fibre tray, microwave and freezer safe.', ARRAY['Pack of 10','Pack of 25','Pack of 50'], 14000, 'prod-bagassetray'),
    ('Packaging', 'Biodegradable Packaging', 'Compostable Cutlery Set', 'Fork, spoon and knife set, fully compostable.', ARRAY['Pack of 10','Pack of 25','Pack of 50'], 10000, 'prod-compostcutlery'),
    ('Packaging', 'Biodegradable Packaging', 'Paper Straw Pack', 'Sturdy paper straws, plastic-free.', ARRAY['Pack of 25','Pack of 50','Pack of 100'], 6000, 'prod-paperstraw'),
    -- Packaging > Bags & Pouches
    ('Packaging', 'Bags & Pouches', 'Piping Bags Disposable', 'Leak-proof disposable piping bags.', ARRAY['Pack of 10','Pack of 25','Pack of 50'], 8000, 'prod-pipingbags'),
    ('Packaging', 'Bags & Pouches', 'Zip Lock Cookie Pouch', 'Resealable pouches for cookies and treats.', ARRAY['Pack of 10','Pack of 25','Pack of 50'], 7000, 'prod-ziplockpouch'),
    ('Packaging', 'Bags & Pouches', 'Kraft Paper Bags', 'Flat-bottom kraft bags for bakery takeaway.', ARRAY['Pack of 10','Pack of 25','Pack of 50'], 6000, 'prod-kraftbags'),
    ('Packaging', 'Bags & Pouches', 'Gift Tote Bag Small', 'Sturdy handle tote for gifting baked goods.', ARRAY['Pack of 10','Pack of 25','Pack of 50'], 12000, 'prod-tote-bag'),
    -- Packaging > Add-ons
    ('Packaging', 'Add-ons', 'Cake Ribbon Roll', 'Satin ribbon roll for finishing cake boxes.', ARRAY['1 roll','5 rolls','10 rolls'], 5000, 'prod-cakeribbon'),
    ('Packaging', 'Add-ons', 'Thank You Stickers', 'Branded thank-you stickers for packaging seals.', ARRAY['Pack of 25','Pack of 50','Pack of 100'], 4000, 'prod-thankyoustickers'),
    ('Packaging', 'Add-ons', 'Cake Box Sealing Tape', 'Printed sealing tape for tamper-evident boxes.', ARRAY['1 roll','5 rolls','10 rolls'], 3500, 'prod-sealingtape'),
    ('Packaging', 'Add-ons', 'Custom Tag Cards', 'Blank tag cards for order notes and pricing.', ARRAY['Pack of 25','Pack of 50','Pack of 100'], 6000, 'prod-tagcards'),
    -- Tools & Equipment > Speciality Tools
    ('Tools & Equipment', 'Speciality Tools', 'Offset Spatula Set', 'Angled spatulas for smooth icing finishes.', ARRAY['Small','Medium','Large'], 25000, 'prod-offsetspatula'),
    ('Tools & Equipment', 'Speciality Tools', 'Cake Turntable', 'Rotating turntable for even icing and decorating.', ARRAY['Standard','Premium','Pro'], 90000, 'prod-turntable'),
    ('Tools & Equipment', 'Speciality Tools', 'Fondant Smoother Set', 'Smoothers for a flawless fondant finish.', ARRAY['Single','Set of 2','Set of 4'], 18000, 'prod-fondantsmoother'),
    ('Tools & Equipment', 'Speciality Tools', 'Piping Nozzle Set', 'Stainless steel nozzles for borders and flowers.', ARRAY['Set of 12','Set of 26','Set of 52'], 30000, 'prod-nozzleset'),
    -- Tools & Equipment > Kitchen Appliances
    ('Tools & Equipment', 'Kitchen Appliances', 'Stand Mixer', 'Heavy-duty stand mixer for batters and doughs.', ARRAY['5L','7L','10L'], 1200000, 'prod-standmixer'),
    ('Tools & Equipment', 'Kitchen Appliances', 'Hand Mixer Electric', 'Lightweight electric hand mixer with multiple speeds.', ARRAY['Basic','Standard','Pro'], 250000, 'prod-handmixer'),
    ('Tools & Equipment', 'Kitchen Appliances', 'Oven Thermometer', 'Accurate oven thermometer for consistent bakes.', ARRAY['Analog','Digital','Pro'], 45000, 'prod-ovenThermo'),
    ('Tools & Equipment', 'Kitchen Appliances', 'Digital Kitchen Weighing Scale', 'Precise digital scale for baking measurements.', ARRAY['5kg','10kg','20kg'], 60000, 'prod-kitchenscale'),
    -- Tools & Equipment > Structure Tools
    ('Tools & Equipment', 'Structure Tools', 'Cake Dowel Rods', 'Support dowels for tiered cake construction.', ARRAY['Pack of 10','Pack of 25','Pack of 50'], 8000, 'prod-doweltods'),
    ('Tools & Equipment', 'Structure Tools', 'Cake Support Plates', 'Separator plates for multi-tier cakes.', ARRAY['Small','Medium','Large'], 15000, 'prod-supportplates'),
    ('Tools & Equipment', 'Structure Tools', 'Bakeware Cooling Rack', 'Wire rack for cooling cakes and cookies evenly.', ARRAY['Small','Medium','Large'], 22000, 'prod-coolingrack'),
    ('Tools & Equipment', 'Structure Tools', 'Cake Leveler Wire', 'Adjustable wire leveler for even cake layers.', ARRAY['Standard','Adjustable','Pro'], 30000, 'prod-cakeleveler'),
    -- Cake Decorations > Edible Decorations
    ('Cake Decorations', 'Edible Decorations', 'Edible Pearls Silver', 'Shimmering silver edible pearls for accents.', ARRAY['Pack of 20','Pack of 50','Pack of 100'], 6000, 'prod-ediblepearls'),
    ('Cake Decorations', 'Edible Decorations', 'Sugar Flowers Assorted', 'Hand-finished sugar flowers, assorted colours.', ARRAY['Pack of 20','Pack of 50','Pack of 100'], 9000, 'prod-sugarflowers'),
    ('Cake Decorations', 'Edible Decorations', 'Edible Glitter Gold', 'Fine edible glitter for a metallic shimmer.', ARRAY['Pack of 20','Pack of 50','Pack of 100'], 5000, 'prod-edibleglitter'),
    ('Cake Decorations', 'Edible Decorations', 'Chocolate Shavings Mix', 'Assorted chocolate shavings and curls.', ARRAY['Pack of 20','Pack of 50','Pack of 100'], 8000, 'prod-chocshavings'),
    -- Cake Decorations > Non Edible Decorations
    ('Cake Decorations', 'Non Edible Decorations', 'Cake Topper Happy Birthday', 'Reusable glitter cake topper.', ARRAY['Single','Pack of 5','Pack of 10'], 7000, 'prod-caketopper'),
    ('Cake Decorations', 'Non Edible Decorations', 'Acrylic Cake Charm Set', 'Decorative acrylic charms for cake tops.', ARRAY['Single','Pack of 5','Pack of 10'], 12000, 'prod-charmset'),
    ('Cake Decorations', 'Non Edible Decorations', 'Fondant Cutter Set', 'Shaped cutters for fondant and gum paste.', ARRAY['Set of 6','Set of 12','Set of 24'], 15000, 'prod-fondantcutterset'),
    ('Cake Decorations', 'Non Edible Decorations', 'Cake Banner Flags', 'Mini bunting flags for cake decoration.', ARRAY['Single','Pack of 5','Pack of 10'], 6000, 'prod-bannerflags'),
    -- Cake Decorations > Add-ons
    ('Cake Decorations', 'Add-ons', 'LED Cake Lights', 'Battery LED lights for a glowing cake display.', ARRAY['Single','Pack of 5','Pack of 10'], 9000, 'prod-ledcakelights'),
    ('Cake Decorations', 'Add-ons', 'Cake Candles Numbered', 'Numbered candles for birthday cakes.', ARRAY['Single','Pack of 5','Pack of 10'], 4000, 'prod-numberedcandles'),
    ('Cake Decorations', 'Add-ons', 'Cake Stencil Set', 'Reusable stencils for powdered sugar designs.', ARRAY['Set of 4','Set of 8','Set of 16'], 11000, 'prod-stencilset'),
    ('Cake Decorations', 'Add-ons', 'Glitter Spray Edible', 'Edible shimmer spray for finishing touches.', ARRAY['Single','Pack of 3','Pack of 6'], 8000, 'prod-glitterspray'),
    -- Seasonal & New Collections > Collections for Festives
    ('Seasonal & New Collections', 'Collections for Festives', 'Diwali Cake Decor Kit', 'Festive Diwali-themed cake decoration kit.', ARRAY['Small Kit','Medium Kit','Large Kit'], 30000, 'prod-diwalikit'),
    ('Seasonal & New Collections', 'Collections for Festives', 'Christmas Theme Topper Set', 'Christmas-themed toppers and picks.', ARRAY['Small Kit','Medium Kit','Large Kit'], 25000, 'prod-christmastopper'),
    ('Seasonal & New Collections', 'Collections for Festives', 'New Year Sparkle Pack', 'Sparkly New Year cake decoration pack.', ARRAY['Small Kit','Medium Kit','Large Kit'], 20000, 'prod-newyearpack'),
    ('Seasonal & New Collections', 'Collections for Festives', 'Rakhi Special Packaging Set', 'Rakhi-themed gifting and packaging set.', ARRAY['Small Kit','Medium Kit','Large Kit'], 18000, 'prod-rakhiset'),
    -- Seasonal & New Collections > Stock Clearance Items
    ('Seasonal & New Collections', 'Stock Clearance Items', 'Assorted Sprinkles Clearance', 'Mixed leftover sprinkle stock at clearance price.', ARRAY['250g','500g','1kg'], 5000, 'prod-sprinklesclearance'),
    ('Seasonal & New Collections', 'Stock Clearance Items', 'Discontinued Cake Boxes', 'Older print-run cake boxes, limited stock.', ARRAY['Pack of 10','Pack of 25','Pack of 50'], 15000, 'prod-boxclearance'),
    ('Seasonal & New Collections', 'Stock Clearance Items', 'Last Season Cutter Sets', 'Previous season fondant cutter sets.', ARRAY['Set of 6','Set of 12','Set of 24'], 9000, 'prod-cutterclearance'),
    ('Seasonal & New Collections', 'Stock Clearance Items', 'Overstock Food Colour Kit', 'Overstocked gel colour kits, discounted.', ARRAY['6x10g','6x25g','6x50g'], 8000, 'prod-colourclearance'),
    -- Seasonal & New Collections > New Arrivals
    ('Seasonal & New Collections', 'New Arrivals', 'Butterfly Wafer Toppers', 'Delicate wafer butterfly toppers, newly launched.', ARRAY['Pack of 20','Pack of 50','Pack of 100'], 7000, 'prod-wafertoppers'),
    ('Seasonal & New Collections', 'New Arrivals', 'Marble Effect Colour Kit', 'New marbling gel colour kit for cakes.', ARRAY['6x10g','6x25g','6x50g'], 12000, 'prod-marblecolour'),
    ('Seasonal & New Collections', 'New Arrivals', '3D Silicone Cake Mould', 'Newly launched 3D silicone cake mould.', ARRAY['Small','Medium','Large'], 35000, 'prod-3dmould'),
    ('Seasonal & New Collections', 'New Arrivals', 'Metallic Edible Paint Set', 'New metallic edible paint set for detailing.', ARRAY['Set of 4','Set of 8','Set of 16'], 14000, 'prod-metallicpaint'),
    -- Bakeware > Cake Moulds
    ('Bakeware', 'Cake Moulds', 'Round Cake Mould', 'Aluminium round cake mould, even heat distribution.', ARRAY['6 inch','8 inch','10 inch'], 25000, 'prod-roundmould'),
    ('Bakeware', 'Cake Moulds', 'Square Cake Mould', 'Aluminium square cake mould with straight edges.', ARRAY['6 inch','8 inch','10 inch'], 26000, 'prod-squaremould'),
    ('Bakeware', 'Cake Moulds', 'Heart Shape Cake Mould', 'Heart-shaped mould for anniversary and love cakes.', ARRAY['6 inch','8 inch','10 inch'], 28000, 'prod-heartmould'),
    ('Bakeware', 'Cake Moulds', 'Bundt Cake Mould', 'Fluted bundt mould for decorative sponge cakes.', ARRAY['6 inch','8 inch','10 inch'], 32000, 'prod-bundtmould'),
    -- Bakeware > Dessert Moulds
    ('Bakeware', 'Dessert Moulds', 'Mini Muffin Mould Tray', 'Non-stick tray for bite-sized muffins.', ARRAY['12 cavity','24 cavity','48 cavity'], 22000, 'prod-mufftray'),
    ('Bakeware', 'Dessert Moulds', 'Silicone Chocolate Mould', 'Flexible silicone mould for chocolates and bonbons.', ARRAY['12 cavity','24 cavity','48 cavity'], 15000, 'prod-chocmould'),
    ('Bakeware', 'Dessert Moulds', 'Popsicle Mould Set', 'Reusable popsicle moulds with sticks.', ARRAY['6 cavity','12 cavity','24 cavity'], 12000, 'prod-popsiclemould'),
    ('Bakeware', 'Dessert Moulds', 'Donut Mould Tray', 'Non-stick tray for baked (not fried) donuts.', ARRAY['6 cavity','12 cavity','24 cavity'], 18000, 'prod-donutmould'),
    -- Bakeware > Paper Moulds
    ('Bakeware', 'Paper Moulds', 'Paper Cupcake Liners', 'Greaseproof paper liners, assorted prints.', ARRAY['Pack of 50','Pack of 100','Pack of 200'], 6000, 'prod-cupcakeliners'),
    ('Bakeware', 'Paper Moulds', 'Paper Loaf Mould', 'Disposable paper loaf moulds for gifting bakes.', ARRAY['Pack of 10','Pack of 25','Pack of 50'], 8000, 'prod-loafmould'),
    ('Bakeware', 'Paper Moulds', 'Muffin Paper Cups Large', 'Extra-large paper cups for jumbo muffins.', ARRAY['Pack of 50','Pack of 100','Pack of 200'], 7000, 'prod-muffincupslarge'),
    ('Bakeware', 'Paper Moulds', 'Panettone Paper Mould', 'Tall paper moulds for panettone and fruit cake.', ARRAY['Pack of 10','Pack of 25','Pack of 50'], 9000, 'prod-panettonemould'),
    -- Bakeware > Silicon Moulds
    ('Bakeware', 'Silicon Moulds', 'Silicone Baking Mat', 'Reusable non-stick silicone baking mat.', ARRAY['Small','Medium','Large'], 20000, 'prod-siliconemat'),
    ('Bakeware', 'Silicon Moulds', 'Silicone Fondant Mould Flowers', 'Detailed flower press moulds for fondant work.', ARRAY['Small','Medium','Large'], 14000, 'prod-silflowermould'),
    ('Bakeware', 'Silicon Moulds', 'Silicone Lace Mat', 'Edible lace texture mat for elegant cake borders.', ARRAY['Small','Medium','Large'], 16000, 'prod-sillacemat'),
    ('Bakeware', 'Silicon Moulds', 'Silicone Ice Cube Cake Pops', 'Cake pop and truffle silicone moulds.', ARRAY['Small','Medium','Large'], 13000, 'prod-silpopmould')
    ) AS t(category_name, sub_category_name, name, description, variants, base_price, image_seed)
  LOOP
    idx := idx + 1;

    -- Deliberate variety so every badge/edge-case in 02_catalog_tab.md §5
    -- and §8 is exercised: trending, new, sale, low stock, out of stock.
    v_is_trending := (idx % 5 = 0);
    v_created_at := CASE WHEN idx % 9 = 0 THEN now() - interval '3 days' ELSE now() - interval '200 days' END;
    v_sale_factor := CASE WHEN idx % 4 = 0 THEN 0.8 ELSE 1.0 END;

    INSERT INTO products (sub_category_id, name, description, is_trending, sort_order, created_at, updated_at)
    VALUES (
      (SELECT sc.id FROM sub_categories sc
         JOIN categories c ON c.id = sc.category_id
        WHERE sc.name = rec.sub_category_name AND c.name = rec.category_name),
      rec.name, rec.description, v_is_trending, idx, v_created_at, v_created_at
    )
    RETURNING id INTO new_product_id;

    FOR v_index IN 1..3 LOOP
      v_name := rec.variants[v_index];
      v_price := round(rec.base_price * multipliers[v_index]);

      v_stock := CASE
        WHEN idx % 7 = 0 AND v_index = 1 THEN 0   -- out of stock (smallest variant only)
        WHEN idx % 6 = 0 THEN 3                    -- low stock
        ELSE 40
      END;

      INSERT INTO product_variants (product_id, name, sku, original_price, current_price, stock_qty, sort_order)
      VALUES (
        new_product_id,
        v_name,
        upper(regexp_replace(rec.image_seed, '[^a-zA-Z0-9]+', '-', 'g')) || '-' || v_index,
        v_price,
        round(v_price * v_sale_factor),
        v_stock,
        v_index
      )
      RETURNING id INTO new_variant_id;

      IF v_index = 1 THEN
        INSERT INTO product_images (product_id, variant_id, storage_path, public_url, sort_order, is_primary) VALUES
          (new_product_id, NULL, 'products/' || new_product_id || '/primary.webp',
           'https://picsum.photos/seed/' || rec.image_seed || '/400', 0, true),
          (new_product_id, NULL, 'products/' || new_product_id || '/gallery/01.webp',
           'https://picsum.photos/seed/' || rec.image_seed || '-alt/400', 1, false);
      END IF;
    END LOOP;
  END LOOP;
END $$;

COMMIT;

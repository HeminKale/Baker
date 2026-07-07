// ─────────────────────────────────────────────────────────────────────────────
// Baker Ally — Figma Screen Generator Plugin
// Generates all major app screens from the Baker Ally architecture specification
//
// Screens generated (3 × 3 grid):
//   Row 0: Login  |  Home  |  Catalog Level 1
//   Row 1: Catalog Level 2  |  Product Detail  |  Order Again
//   Row 2: Cart / Checkout  |  Order Confirmation  |  Profile Overlay
// ─────────────────────────────────────────────────────────────────────────────

const SW = 390;   // iPhone 14 Pro width
const SH = 844;   // iPhone 14 Pro height
const GAP = 80;   // Gap between screens on the Figma canvas

// ─── Brand Palette ────────────────────────────────────────────────────────────
const C = {
  primary:    { r: 0.831, g: 0.659, b: 0.325 }, // #D4A853 golden amber
  primaryBg:  { r: 0.992, g: 0.957, b: 0.878 }, // #FDF4E0 light amber fill
  bg:         { r: 1.000, g: 1.000, b: 1.000 }, // #FFFFFF
  surface:    { r: 0.965, g: 0.953, b: 0.937 }, // #F6F3EF warm light grey
  imgBg:      { r: 0.918, g: 0.902, b: 0.882 }, // #EAE6E1 image placeholder
  border:     { r: 0.894, g: 0.867, b: 0.831 }, // #E4DDD4
  text:       { r: 0.098, g: 0.098, b: 0.098 }, // #191919
  textSub:    { r: 0.400, g: 0.400, b: 0.400 }, // #666666
  textMuted:  { r: 0.627, g: 0.627, b: 0.627 }, // #A0A0A0
  white:      { r: 1.000, g: 1.000, b: 1.000 },
  red:        { r: 0.886, g: 0.224, b: 0.224 }, // #E23939
  redBg:      { r: 0.996, g: 0.925, b: 0.925 }, // #FEDEDE
  green:      { r: 0.200, g: 0.698, b: 0.408 }, // #33B268
  greenBg:    { r: 0.878, g: 0.961, b: 0.910 }, // #E0F5E8
  amber:      { r: 0.957, g: 0.659, b: 0.271 }, // #F4A845
  blue:       { r: 0.235, g: 0.584, b: 0.878 }, // #3C95E0
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

function solid(color) {
  return [{ type: 'SOLID', color: color }];
}

// Position a screen frame on the canvas grid
function screenPos(col, row) {
  return { x: col * (SW + GAP), y: row * (SH + GAP) };
}

// Create a top-level screen frame
function mkScreen(name, col, row) {
  const pos = screenPos(col, row);
  const f = figma.createFrame();
  f.name = name;
  f.resize(SW, SH);
  f.x = pos.x;
  f.y = pos.y;
  f.fills = solid(C.bg);
  f.clipsContent = true;
  return f;
}

// Create a plain rectangle
function mkRect(w, h, color, radius) {
  const r = figma.createRectangle();
  r.resize(w, h);
  r.fills = color ? solid(color) : [];
  if (radius) r.cornerRadius = radius;
  return r;
}

// Create a text node — fonts MUST be loaded before calling this
function mkText(str, size, weight, color, maxW) {
  const t = figma.createText();
  const style = weight >= 700 ? 'Bold' : weight >= 600 ? 'Semi Bold' : weight >= 500 ? 'Medium' : 'Regular';
  t.fontName = { family: 'Inter', style: style };
  t.fontSize = size;
  t.fills = solid(color);
  t.characters = String(str);
  if (maxW != null) {
    t.textAutoResize = 'HEIGHT';
    if (t.width > maxW) t.resize(maxW, t.height);
  }
  return t;
}

// Create an image placeholder rectangle with a centred label
function mkImgBox(w, h, label, radius) {
  const box = figma.createFrame();
  box.resize(w, h);
  box.fills = solid(C.imgBg);
  if (radius) box.cornerRadius = radius;
  if (label) {
    const t = mkText(label, 11, 400, C.textMuted);
    t.x = Math.max(0, (w - t.width) / 2);
    t.y = Math.max(0, (h - t.height) / 2);
    box.appendChild(t);
  }
  return box;
}

// Create a small filled badge pill
function mkBadge(label, bg, textColor) {
  const box = figma.createFrame();
  box.layoutMode = 'HORIZONTAL';
  box.primaryAxisSizingMode = 'AUTO';
  box.counterAxisSizingMode = 'AUTO';
  box.paddingTop = 3; box.paddingBottom = 3;
  box.paddingLeft = 7; box.paddingRight = 7;
  box.cornerRadius = 4;
  box.fills = solid(bg);
  const t = mkText(label, 10, 500, textColor);
  box.appendChild(t);
  return box;
}

// Add a 1px horizontal divider line to a parent at a given y
function mkDivider(w, y, parent) {
  const d = mkRect(w, 1, C.border);
  d.x = 0; d.y = y;
  parent.appendChild(d);
}

// Create a quantity stepper (– qty +)
function mkStepper(x, y, qty, parent) {
  const box = figma.createFrame();
  box.resize(88, 30);
  box.x = x; box.y = y;
  box.cornerRadius = 8;
  box.fills = solid(C.primary);
  const m = mkText('−', 16, 700, C.white);
  m.x = 10; m.y = 6; box.appendChild(m);
  const q = mkText(String(qty), 13, 600, C.white);
  q.x = 38; q.y = 8; box.appendChild(q);
  const p = mkText('+', 15, 700, C.white);
  p.x = 66; p.y = 7; box.appendChild(p);
  parent.appendChild(box);
  return box;
}

// ─── Shared Components ────────────────────────────────────────────────────────

// Global top bar: address pill | (optional search icon) | bell | avatar
function mkTopBar(showSearchIcon) {
  const bar = figma.createFrame();
  bar.name = 'Top Bar';
  bar.resize(SW, 56);
  bar.x = 0; bar.y = 0;
  bar.fills = solid(C.bg);

  // Address pill
  const pill = figma.createFrame();
  pill.resize(148, 32);
  pill.x = 16; pill.y = 12;
  pill.cornerRadius = 8;
  pill.fills = solid(C.surface);
  bar.appendChild(pill);
  const addrIcon = mkText('📍', 12, 400, C.primary);
  addrIcon.x = 8; addrIcon.y = 8; pill.appendChild(addrIcon);
  const addrLbl = mkText('Home  ▾', 12, 500, C.text);
  addrLbl.x = 26; addrLbl.y = 9; pill.appendChild(addrLbl);

  // Bell
  const bell = mkText('🔔', 18, 400, C.textSub);
  bell.x = showSearchIcon ? SW - 90 : SW - 58;
  bell.y = 17; bar.appendChild(bell);

  // Avatar circle
  const av = mkRect(30, 30, C.primary, 15);
  av.x = SW - 46; av.y = 13; bar.appendChild(av);
  const avT = mkText('P', 12, 700, C.white);
  avT.x = SW - 46 + 11; avT.y = 17; bar.appendChild(avT);

  // Search icon (not on Home where bar is full-width)
  if (showSearchIcon) {
    const si = mkText('🔍', 18, 400, C.textSub);
    si.x = SW - 118; si.y = 17; bar.appendChild(si);
  }

  return bar;
}

// Full-width search bar (Home screen)
function mkSearchBar(y) {
  const box = figma.createFrame();
  box.resize(SW - 32, 44);
  box.x = 16; box.y = y;
  box.cornerRadius = 12;
  box.fills = solid(C.surface);
  box.strokes = [{ type: 'SOLID', color: C.border }];
  box.strokeWeight = 1;
  const si = mkText('🔍', 16, 400, C.textMuted);
  si.x = 12; si.y = 13; box.appendChild(si);
  const ph = mkText('Search ingredients, packaging...', 13, 400, C.textMuted);
  ph.x = 36; ph.y = 14; box.appendChild(ph);
  const mic = mkText('🎤', 15, 400, C.textMuted);
  mic.x = SW - 32 - 34; mic.y = 14; box.appendChild(mic);
  return box;
}

// Bottom navigation bar with active tab highlight
function mkBottomNav(active) {
  const nav = figma.createFrame();
  nav.name = 'Bottom Nav';
  nav.resize(SW, 80);
  nav.y = SH - 80;
  nav.fills = solid(C.bg);
  mkDivider(SW, 0, nav);

  const tabs = [
    { id: 'home', icon: '🏠', label: 'Home' },
    { id: 'catalog', icon: '📦', label: 'Catalog' },
    { id: 'order-again', icon: '🔄', label: 'Order Again' },
    { id: 'brownie', icon: '🍪', label: '🍪' },
    { id: 'cart', icon: '🛒', label: 'Cart' },
  ];
  const tabW = SW / tabs.length;

  tabs.forEach(function(tab, i) {
    const isActive = tab.id === active;
    const cx = i * tabW + tabW / 2;

    const icon = mkText(tab.icon, 20, 400, isActive ? C.primary : C.textMuted);
    icon.x = cx - icon.width / 2; icon.y = 10;
    nav.appendChild(icon);

    const lbl = mkText(tab.label, 10, isActive ? 600 : 400, isActive ? C.primary : C.textMuted);
    lbl.x = cx - lbl.width / 2; lbl.y = 36;
    nav.appendChild(lbl);

    if (tab.id === 'cart') {
      const badge = mkRect(16, 16, C.red, 8);
      badge.x = cx + 4; badge.y = 6; nav.appendChild(badge);
      const bn = mkText('3', 9, 700, C.white);
      bn.x = badge.x + 4; bn.y = badge.y + 3; nav.appendChild(bn);
    }
  });

  return nav;
}

// Section row header: bold title on left + "See all →" on right
function mkSectionHeader(title, y, parent) {
  const t = mkText(title, 14, 700, C.text);
  t.x = 16; t.y = y; parent.appendChild(t);
  const sa = mkText('See all →', 12, 500, C.primary);
  sa.x = SW - 16 - sa.width; sa.y = y + 1; parent.appendChild(sa);
}

// Product tile used on Home, Catalog L2, Order Again, Wishlist
function mkProductTile(product, x, y, parent) {
  const TW = 156, TH = 218;
  const tile = figma.createFrame();
  tile.resize(TW, TH);
  tile.x = x; tile.y = y;
  tile.cornerRadius = 10;
  tile.fills = solid(C.bg);
  tile.strokes = [{ type: 'SOLID', color: C.border }];
  tile.strokeWeight = 1;

  const img = mkImgBox(TW, 112, product.emoji || '', 0);
  img.topLeftRadius = 10; img.topRightRadius = 10;
  tile.appendChild(img);

  if (product.trending) {
    const b = mkBadge('Trending', C.amber, C.white);
    b.x = 6; b.y = 6; tile.appendChild(b);
  }

  const name = mkText(product.name, 12, 600, C.text, TW - 14);
  name.x = 7; name.y = 118; tile.appendChild(name);

  const variant = mkText(product.variant, 10, 400, C.textMuted);
  variant.x = 7; variant.y = 132; tile.appendChild(variant);

  var priceY = 147;
  if (product.originalPrice) {
    const op = mkText('₹' + product.originalPrice, 11, 400, C.textMuted);
    op.x = 7; op.y = priceY; tile.appendChild(op);
    const sl = mkRect(op.width, 1, C.textMuted);
    sl.x = 7; sl.y = priceY + 7; tile.appendChild(sl);
    priceY += 13;
  }
  const pr = mkText('₹' + product.price, 14, 700, C.text);
  pr.x = 7; pr.y = priceY; tile.appendChild(pr);

  const btn = figma.createFrame();
  btn.resize(TW - 14, 28);
  btn.x = 7; btn.y = TH - 35;
  btn.cornerRadius = 8;
  btn.fills = solid(C.primaryBg);
  btn.strokes = [{ type: 'SOLID', color: C.primary }];
  btn.strokeWeight = 1;
  tile.appendChild(btn);
  const bt = mkText('+ Add to Cart', 11, 600, C.primary);
  bt.x = (TW - 14 - bt.width) / 2; bt.y = 8;
  btn.appendChild(bt);

  parent.appendChild(tile);
  return tile;
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 1 — Login / OTP
// ─────────────────────────────────────────────────────────────────────────────
function buildLoginScreen(col, row) {
  const s = mkScreen('01 · Login / OTP', col, row);

  // Top amber wash
  const topWash = mkRect(SW, 300, C.primaryBg);
  topWash.y = 0; s.appendChild(topWash);

  // Logo box
  const logo = mkRect(80, 80, C.primary, 20);
  logo.x = (SW - 80) / 2; logo.y = 80; s.appendChild(logo);
  const logoT = mkText('BA', 28, 700, C.white);
  logoT.x = (SW - logoT.width) / 2; logoT.y = 104; s.appendChild(logoT);

  const appName = mkText('Baker Ally', 24, 700, C.text);
  appName.x = (SW - appName.width) / 2; appName.y = 178; s.appendChild(appName);
  const tagline = mkText('Your Baking Supply Partner', 13, 400, C.textSub);
  tagline.x = (SW - tagline.width) / 2; tagline.y = 208; s.appendChild(tagline);

  // Card
  const card = figma.createFrame();
  card.resize(SW - 32, 370);
  card.x = 16; card.y = 290;
  card.cornerRadius = 20;
  card.fills = solid(C.bg);
  s.appendChild(card);

  const cardTitle = mkText('Login / Sign Up', 18, 700, C.text);
  cardTitle.x = 24; cardTitle.y = 28; card.appendChild(cardTitle);
  const cardSub = mkText('Enter your phone number to continue', 13, 400, C.textSub);
  cardSub.x = 24; cardSub.y = 54; card.appendChild(cardSub);

  // Phone input field
  const phoneField = figma.createFrame();
  phoneField.resize(card.width - 48, 48);
  phoneField.x = 24; phoneField.y = 88;
  phoneField.cornerRadius = 10;
  phoneField.fills = solid(C.surface);
  phoneField.strokes = [{ type: 'SOLID', color: C.border }];
  phoneField.strokeWeight = 1;
  card.appendChild(phoneField);
  const prefix = mkText('+91', 13, 600, C.text);
  prefix.x = 14; prefix.y = 16; phoneField.appendChild(prefix);
  const divPipe = mkRect(1, 24, C.border);
  divPipe.x = 44; divPipe.y = 12; phoneField.appendChild(divPipe);
  const numHint = mkText('98765 43210', 13, 400, C.textMuted);
  numHint.x = 56; numHint.y = 16; phoneField.appendChild(numHint);

  // Get OTP button
  const otpBtn = figma.createFrame();
  otpBtn.resize(card.width - 48, 48);
  otpBtn.x = 24; otpBtn.y = 156;
  otpBtn.cornerRadius = 10;
  otpBtn.fills = solid(C.primary);
  card.appendChild(otpBtn);
  const otpT = mkText('Get OTP', 15, 600, C.white);
  otpT.x = (card.width - 48 - otpT.width) / 2; otpT.y = 15;
  otpBtn.appendChild(otpT);

  const orT = mkText('or continue with', 12, 400, C.textMuted);
  orT.x = (card.width - orT.width) / 2; orT.y = 222; card.appendChild(orT);

  // Google sign-in button
  const gBtn = figma.createFrame();
  gBtn.resize(card.width - 48, 48);
  gBtn.x = 24; gBtn.y = 248;
  gBtn.cornerRadius = 10;
  gBtn.fills = solid(C.bg);
  gBtn.strokes = [{ type: 'SOLID', color: C.border }];
  gBtn.strokeWeight = 1;
  card.appendChild(gBtn);
  const gT = mkText('G    Continue with Google', 13, 500, C.text);
  gT.x = (card.width - 48 - gT.width) / 2; gT.y = 15; gBtn.appendChild(gT);

  const terms = mkText('By continuing, you agree to our Terms & Privacy Policy', 11, 400, C.textMuted, card.width - 48);
  terms.x = 24; terms.y = 316;
  terms.textAlignHorizontal = 'CENTER';
  card.appendChild(terms);

  figma.currentPage.appendChild(s);
  return s;
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 2 — Home
// ─────────────────────────────────────────────────────────────────────────────
function buildHomeScreen(col, row) {
  const s = mkScreen('02 · Home', col, row);
  s.appendChild(mkTopBar(false));
  s.appendChild(mkSearchBar(64));

  var products = [
    [
      { name: 'Fresh Cream 25%', variant: '500ml', price: '95', originalPrice: '120', emoji: '🥛' },
      { name: 'Dark Compound Choc', variant: '1kg', price: '380', trending: true, emoji: '🍫' },
    ],
    [
      { name: 'Cake Box 8 inch', variant: 'Pack of 10', price: '150', originalPrice: '180', emoji: '📦' },
      { name: 'Silicon Mould', variant: '6-cup round', price: '220', originalPrice: '280', emoji: '🔵' },
    ],
    [
      { name: 'Piping Bags 100', variant: 'Disposable', price: '120', trending: true, emoji: '🎂' },
      { name: 'Food Colour Set', variant: '12 colours', price: '340', emoji: '🎨' },
    ],
  ];

  var sections = ['Newly Launched', 'New Offers', 'Trending Now'];
  var sectionY = 120;

  sections.forEach(function(title, si) {
    if (sectionY > SH - 100) return;
    mkSectionHeader(title, sectionY, s);
    var row2 = products[si];
    row2.forEach(function(p, pi) {
      mkProductTile(p, 16 + pi * 166, sectionY + 22, s);
    });
    sectionY += 262;
  });

  s.appendChild(mkBottomNav('home'));
  figma.currentPage.appendChild(s);
  return s;
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 3 — Catalog Level 1 (Category Browser)
// ─────────────────────────────────────────────────────────────────────────────
function buildCatalogL1Screen(col, row) {
  const s = mkScreen('03 · Catalog — Level 1', col, row);
  s.appendChild(mkTopBar(true));

  const title = mkText('Catalog', 18, 700, C.text);
  title.x = 16; title.y = 64; s.appendChild(title);

  var cats = [
    { name: 'Ingredients', subs: ['Creams', 'Cocoa & Chocs', 'Fruit Fillings', 'Food Colours'] },
    { name: 'Packaging', subs: ['Cake Boxes', 'Dessert Boxes', 'PVC & Acrylic', 'Bags & Pouches'] },
    { name: 'Tools & Equipment', subs: ['Speciality Tools', 'Kitchen Apps', 'Structure Tools'] },
    { name: 'Cake Decorations', subs: ['Edible Decor', 'Non-Edible', 'Add-ons'] },
    { name: 'Bakeware', subs: ['Cake Moulds', 'Dessert Moulds', 'Silicon Moulds'] },
  ];

  var yOff = 94;

  cats.forEach(function(cat) {
    if (yOff + 120 > SH - 80) return;

    const catLbl = mkText(cat.name, 13, 700, C.text);
    catLbl.x = 16; catLbl.y = yOff; s.appendChild(catLbl);
    yOff += 22;

    var TILE_W = 80, TILE_H = 88;
    cat.subs.forEach(function(sub, si) {
      var tx = 16 + si * (TILE_W + 8);
      if (tx + TILE_W > SW - 16) return;

      const tile = figma.createFrame();
      tile.resize(TILE_W, TILE_H);
      tile.x = tx; tile.y = yOff;
      tile.cornerRadius = 10;
      tile.fills = solid(C.surface);
      s.appendChild(tile);

      const img = mkImgBox(TILE_W, 54, '', 0);
      img.topLeftRadius = 10; img.topRightRadius = 10;
      tile.appendChild(img);

      const lbl = mkText(sub, 10, 500, C.text, TILE_W - 8);
      lbl.x = 4; lbl.y = 58;
      lbl.textAlignHorizontal = 'CENTER';
      tile.appendChild(lbl);
    });

    yOff += TILE_H + 12;
  });

  s.appendChild(mkBottomNav('catalog'));
  figma.currentPage.appendChild(s);
  return s;
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 4 — Catalog Level 2 (Wide Sidebar + Scrollspy Product Grid)
//
// Sidebar: 64px wide, full subcategory names wrapping to 2 lines, center-aligned.
// Active item shows all three cues: 4px indicator bar flush left + tinted bg + bold colored text.
// Right panel: section headers + 2-column product grid with image, name, size,
// strikethrough price, and "+ Add" button.
// ─────────────────────────────────────────────────────────────────────────────
function buildCatalogL2Screen(col, row) {
  const s = mkScreen('04 · Catalog — Level 2 (Ingredients)', col, row);

  const HEADER_H = 48;
  const NAV_H = 80;
  const CONTENT_H = SH - HEADER_H - NAV_H;  // 716px
  const SIDEBAR_W = 64;
  const RIGHT_X = SIDEBAR_W + 1;             // +1 for the divider line
  const RIGHT_W = SW - RIGHT_X;              // 325px

  // ── Header bar ──────────────────────────────────────────────────────────────
  const hdr = figma.createFrame();
  hdr.resize(SW, HEADER_H); hdr.y = 0; hdr.fills = solid(C.bg); s.appendChild(hdr);

  const back = mkText('←', 20, 400, C.text);
  back.x = 16; back.y = 12; hdr.appendChild(back);

  const htitle = mkText('Ingredients', 15, 700, C.text);
  htitle.x = (SW - htitle.width) / 2; htitle.y = 14; hdr.appendChild(htitle);

  const filterBtn = figma.createFrame();
  filterBtn.resize(78, 28); filterBtn.x = SW - 94; filterBtn.y = 10;
  filterBtn.cornerRadius = 8; filterBtn.fills = solid(C.surface);
  filterBtn.strokes = [{ type: 'SOLID', color: C.border }]; filterBtn.strokeWeight = 1;
  hdr.appendChild(filterBtn);
  const filterT = mkText('⚙ Filter', 12, 500, C.textSub);
  filterT.x = 8; filterT.y = 7; filterBtn.appendChild(filterT);

  // ── Left sidebar background ──────────────────────────────────────────────────
  const sidebarBg = mkRect(SIDEBAR_W, CONTENT_H, C.surface);
  sidebarBg.x = 0; sidebarBg.y = HEADER_H; s.appendChild(sidebarBg);

  // Subcategory items — icon + full name wrapping to 2 lines, center-aligned
  var subcats = [
    { name: 'Creams',              icon: '🥛' },
    { name: 'Cocoa & Chocolates',  icon: '🍫' },
    { name: 'Fruit Fillings',      icon: '🍓' },
    { name: 'Stabilizers',         icon: '🧪' },
    { name: 'Mixes',               icon: '🥣' },
    { name: 'Food Colours',        icon: '🎨' },
    { name: 'Flavours',            icon: '🌿' },
  ];
  const ITEM_H = Math.floor(CONTENT_H / subcats.length);  // ~102px each
  const ICON_SIZE = 26;   // emoji font size
  const ICON_LBL_GAP = 4; // gap between icon and text
  const LBL_LINE_H = 13;  // px per text line
  const LBL_LINES = 2;
  const BLOCK_H = ICON_SIZE + ICON_LBL_GAP + LBL_LINE_H * LBL_LINES; // total icon+label block

  subcats.forEach(function(sc, i) {
    var isActive = i === 0;
    var itemY = HEADER_H + i * ITEM_H;

    // Cue 1 — light tinted background (active only)
    if (isActive) {
      const activeBg = mkRect(SIDEBAR_W, ITEM_H, C.primaryBg);
      activeBg.x = 0; activeBg.y = itemY; s.appendChild(activeBg);

      // Cue 2 — 4dp indicator bar, flush against the left edge
      const bar = mkRect(4, ITEM_H, C.primary);
      bar.x = 0; bar.y = itemY; s.appendChild(bar);
    }

    // Hairline divider between items (skip first)
    if (i > 0) {
      const div = mkRect(SIDEBAR_W, 1, C.border);
      div.x = 0; div.y = itemY; s.appendChild(div);
    }

    // Vertical start of the icon+label block, centred in the slot
    var blockTop = itemY + Math.round((ITEM_H - BLOCK_H) / 2);

    // Emoji icon — centred horizontally
    const ico = mkText(sc.icon, ICON_SIZE, 400, C.text);
    ico.textAlignHorizontal = 'CENTER';
    ico.x = Math.round((SIDEBAR_W - ico.width) / 2);
    ico.y = blockTop;
    s.appendChild(ico);

    // Category label below icon — wraps to 2 lines, center-aligned
    const lbl = mkText(sc.name, 10, isActive ? 600 : 400, isActive ? C.primary : C.textMuted, SIDEBAR_W - 8);
    lbl.textAlignHorizontal = 'CENTER';
    lbl.lineHeight = { value: LBL_LINE_H, unit: 'PIXELS' };
    lbl.x = 4;
    lbl.y = blockTop + ICON_SIZE + ICON_LBL_GAP;
    s.appendChild(lbl);
  });

  // Vertical divider between sidebar and grid
  const vDiv = mkRect(1, CONTENT_H, C.border);
  vDiv.x = SIDEBAR_W; vDiv.y = HEADER_H; s.appendChild(vDiv);

  // ── Right panel — section headers + 2-column product grid ───────────────────
  const PAD = 8;
  const TILE_GAP = 8;
  const TILE_W = Math.floor((RIGHT_W - PAD * 2 - TILE_GAP) / 2);  // ~150px
  const TILE_H = 205;

  var sections = [
    {
      name: 'Creams', count: 24,
      items: [
        { name: 'Fresh Cream 25%', variant: '500ml', price: '95', originalPrice: '120' },
        { name: 'Whipping Cream', variant: '1 Litre', price: '180' },
        { name: 'Heavy Cream', variant: '200ml', price: '45', trending: true },
        { name: 'Pastry Cream Mix', variant: '500g', price: '220', originalPrice: '260' },
      ]
    },
    {
      name: 'Cocoa & Chocolates', count: 18,
      items: [
        { name: 'Dark Compound Chocolate', variant: '1kg', price: '380', trending: true },
        { name: 'White Chocolate Chips', variant: '500g', price: '290', originalPrice: '340' },
      ]
    },
  ];

  var gridY = HEADER_H + 6;

  sections.forEach(function(sec) {
    if (gridY + 40 > SH - NAV_H) return;

    // Section header row
    const secLbl = mkText(sec.name, 13, 700, C.text);
    secLbl.x = RIGHT_X + PAD; secLbl.y = gridY + 8; s.appendChild(secLbl);

    const secCount = mkText(String(sec.count) + ' items', 10, 400, C.textMuted);
    secCount.x = SW - PAD - secCount.width; secCount.y = gridY + 10; s.appendChild(secCount);

    // Underline below header
    const secLine = mkRect(RIGHT_W - PAD, 1, C.border);
    secLine.x = RIGHT_X + PAD; secLine.y = gridY + 32; s.appendChild(secLine);
    gridY += 40;

    // Product rows — 2 tiles per row
    for (var i = 0; i < sec.items.length; i += 2) {
      if (gridY + TILE_H > SH - NAV_H) break;

      [sec.items[i], sec.items[i + 1]].forEach(function(p, pi) {
        if (!p) return;
        var tileX = RIGHT_X + PAD + pi * (TILE_W + TILE_GAP);

        const tile = figma.createFrame();
        tile.resize(TILE_W, TILE_H);
        tile.x = tileX; tile.y = gridY;
        tile.cornerRadius = 10; tile.fills = solid(C.bg);
        tile.strokes = [{ type: 'SOLID', color: C.border }]; tile.strokeWeight = 1;
        s.appendChild(tile);

        // Product image placeholder
        const img = mkImgBox(TILE_W, 108, '', 0);
        img.topLeftRadius = 10; img.topRightRadius = 10; tile.appendChild(img);

        // Trending badge overlaid on image
        if (p.trending) {
          const tb = mkBadge('Trending', C.amber, C.white);
          tb.x = 5; tb.y = 5; tile.appendChild(tb);
        }

        // Product name — up to 2 lines
        const name = mkText(p.name, 11, 600, C.text, TILE_W - 12);
        name.x = 6; name.y = 113; tile.appendChild(name);

        // Size / variant
        const vr = mkText(p.variant, 10, 400, C.textMuted);
        vr.x = 6; vr.y = name.y + name.height + 2; tile.appendChild(vr);

        // Price — strikethrough original + current, or just current
        var priceY = vr.y + vr.height + 4;
        if (p.originalPrice) {
          const op = mkText('₹' + p.originalPrice, 10, 400, C.textMuted);
          op.x = 6; op.y = priceY; tile.appendChild(op);
          // Manual strikethrough line through the middle of the text
          const sl = mkRect(op.width, 1, C.textMuted);
          sl.x = 6; sl.y = priceY + 7; tile.appendChild(sl);
          priceY += 14;
        }
        const pr = mkText('₹' + p.price, 13, 700, C.text);
        pr.x = 6; pr.y = priceY; tile.appendChild(pr);

        // "+ Add" button — pinned to bottom of tile
        const btn = figma.createFrame();
        btn.resize(TILE_W - 12, 28);
        btn.x = 6; btn.y = TILE_H - 34;
        btn.cornerRadius = 7; btn.fills = solid(C.primaryBg);
        btn.strokes = [{ type: 'SOLID', color: C.primary }]; btn.strokeWeight = 1;
        tile.appendChild(btn);
        const bt = mkText('+ Add', 11, 600, C.primary);
        bt.x = (TILE_W - 12 - bt.width) / 2; bt.y = 8; btn.appendChild(bt);
      });

      gridY += TILE_H + 10;
    }

    gridY += 10; // gap between sections
  });

  s.appendChild(mkBottomNav('catalog'));
  figma.currentPage.appendChild(s);
  return s;
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 5 — Product Detail
// ─────────────────────────────────────────────────────────────────────────────
function buildProductDetailScreen(col, row) {
  const s = mkScreen('05 · Product Detail — Fresh Cream 25%', col, row);

  const hdr = figma.createFrame();
  hdr.resize(SW, 48); hdr.y = 0; hdr.fills = solid(C.bg); s.appendChild(hdr);
  const back = mkText('←', 20, 400, C.text);
  back.x = 16; back.y = 12; hdr.appendChild(back);
  const ht = mkText('Fresh Cream 25%', 14, 600, C.text);
  ht.x = (SW - ht.width) / 2; ht.y = 14; hdr.appendChild(ht);

  // Big product image
  const bigImg = mkImgBox(SW, 270, 'Product Image', 0);
  bigImg.y = 48; s.appendChild(bigImg);

  // Gallery dots
  var dotsY = 325;
  [0, 1, 2, 3].forEach(function(i) {
    var isActive = i === 1;
    var dot = mkRect(isActive ? 18 : 6, 6, isActive ? C.primary : C.border, 3);
    dot.x = SW / 2 - 20 + i * 12; dot.y = dotsY; s.appendChild(dot);
  });

  // Name + wishlist
  const pName = mkText('Fresh Cream 25%', 18, 700, C.text);
  pName.x = 16; pName.y = 342; s.appendChild(pName);
  const heart = mkText('♡', 22, 400, C.textMuted);
  heart.x = SW - 38; heart.y = 340; s.appendChild(heart);

  const crumb = mkText('Ingredients · Creams', 12, 400, C.textMuted);
  crumb.x = 16; crumb.y = 368; s.appendChild(crumb);

  // Pricing
  const op = mkText('₹120', 13, 400, C.textMuted);
  op.x = 16; op.y = 392; s.appendChild(op);
  const sl = mkRect(op.width, 1, C.textMuted);
  sl.x = 16; sl.y = 400; s.appendChild(sl);
  const cp = mkText('₹95', 18, 700, C.text);
  cp.x = 16 + op.width + 8; cp.y = 388; s.appendChild(cp);
  const offB = mkBadge('21% off', C.green, C.white);
  offB.x = 16 + op.width + 8 + cp.width + 8; offB.y = 394; s.appendChild(offB);

  // Variant chips
  const vLabel = mkText('Select Variant', 12, 600, C.text);
  vLabel.x = 16; vLabel.y = 422; s.appendChild(vLabel);
  var variants = ['200ml', '500ml', '1 L'];
  variants.forEach(function(v, i) {
    var isSelected = i === 1;
    const chip = figma.createFrame();
    chip.resize(70, 32); chip.x = 16 + i * 78; chip.y = 440;
    chip.cornerRadius = 8;
    chip.fills = solid(isSelected ? C.primary : C.surface);
    chip.strokes = [{ type: 'SOLID', color: isSelected ? C.primary : C.border }];
    chip.strokeWeight = 1; s.appendChild(chip);
    const ct = mkText(v, 12, isSelected ? 600 : 400, isSelected ? C.white : C.text);
    ct.x = (70 - ct.width) / 2; ct.y = 9; chip.appendChild(ct);
  });

  // Description
  const dl = mkText('Description', 13, 700, C.text);
  dl.x = 16; dl.y = 486; s.appendChild(dl);
  mkDivider(SW - 32, 503, s);
  const dt = mkText('High-quality fresh cream ideal for whipping, ganache, and mousse. No added preservatives. Perfect for professional bakers.', 12, 400, C.textSub, SW - 32);
  dt.x = 16; dt.y = 508; s.appendChild(dt);

  // You Might Also Like
  const ymll = mkText('You Might Also Like', 13, 700, C.text);
  ymll.x = 16; ymll.y = 570; s.appendChild(ymll);
  mkDivider(SW - 32, 588, s);
  var relatedProducts = ['Whipping Cream', 'Heavy Cream', 'Pastry Mix'];
  relatedProducts.forEach(function(rp, i) {
    const mt = figma.createFrame();
    mt.resize(108, 80); mt.x = 16 + i * 116; mt.y = 594;
    mt.cornerRadius = 8; mt.fills = solid(C.surface); s.appendChild(mt);
    const mImg = mkImgBox(108, 52, '', 0);
    mImg.topLeftRadius = 8; mImg.topRightRadius = 8; mt.appendChild(mImg);
    const mn = mkText(rp, 10, 500, C.text, 100);
    mn.x = 4; mn.y = 56; mt.appendChild(mn);
  });

  // Fixed Add to Cart CTA (above bottom nav)
  const ctaBorder = mkRect(SW, 1, C.border);
  ctaBorder.y = SH - 80 - 65; s.appendChild(ctaBorder);
  const ctaArea = mkRect(SW, 64, C.bg);
  ctaArea.y = SH - 80 - 64; s.appendChild(ctaArea);
  const ctaBtn = figma.createFrame();
  ctaBtn.resize(SW - 32, 48); ctaBtn.x = 16; ctaBtn.y = SH - 80 - 56;
  ctaBtn.cornerRadius = 12; ctaBtn.fills = solid(C.primary); s.appendChild(ctaBtn);
  const ctaT = mkText('+ Add to Cart  ·  ₹95', 14, 700, C.white);
  ctaT.x = (SW - 32 - ctaT.width) / 2; ctaT.y = 14; ctaBtn.appendChild(ctaT);

  s.appendChild(mkBottomNav('catalog'));
  figma.currentPage.appendChild(s);
  return s;
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 6 — Order Again
// ─────────────────────────────────────────────────────────────────────────────
function buildOrderAgainScreen(col, row) {
  const s = mkScreen('06 · Order Again', col, row);
  s.appendChild(mkTopBar(true));

  const title = mkText('Order Again', 18, 700, C.text);
  title.x = 16; title.y = 64; s.appendChild(title);

  // --- Section 1: Frequently Bought Together ---
  const fbtLbl = mkText('FREQUENTLY BOUGHT TOGETHER', 10, 600, C.textMuted);
  fbtLbl.x = 16; fbtLbl.y = 92; s.appendChild(fbtLbl);

  var groups = [
    { a: '🥛', b: '🍫', name: 'Fresh Cream + Dark Choc', extra: '+2', price: '₹1,240', count: '5 items' },
    { a: '📦', b: '🎂', name: 'Cake Box + Piping Bags', price: '₹270', count: '2 items' },
    { a: '🎨', b: '🫙', name: 'Food Colours + Vanilla', extra: '+1', price: '₹405', count: '3 items' },
  ];
  groups.forEach(function(g, i) {
    const card = figma.createFrame();
    card.resize(152, 140); card.x = 16 + i * 160; card.y = 108;
    card.cornerRadius = 12; card.fills = solid(C.bg);
    card.strokes = [{ type: 'SOLID', color: C.border }]; card.strokeWeight = 1;
    s.appendChild(card);

    const img1 = mkImgBox(52, 52, g.a, 8);
    img1.x = 8; img1.y = 8; card.appendChild(img1);
    const plus = mkText('+', 14, 700, C.textMuted);
    plus.x = 64; plus.y = 24; card.appendChild(plus);
    const img2 = mkImgBox(52, 52, g.b, 8);
    img2.x = 80; img2.y = 8; card.appendChild(img2);
    if (g.extra) {
      const eBg = mkRect(28, 16, C.textSub, 4);
      eBg.x = 114; eBg.y = 46; card.appendChild(eBg);
      const eT = mkText(g.extra, 9, 500, C.white);
      eT.x = 118; eT.y = 49; card.appendChild(eT);
    }

    const gPrice = mkText(g.price, 13, 700, C.text);
    gPrice.x = 8; gPrice.y = 68; card.appendChild(gPrice);
    const gCount = mkText(g.count, 10, 400, C.textMuted);
    gCount.x = 8; gCount.y = 83; card.appendChild(gCount);

    const addAll = figma.createFrame();
    addAll.resize(136, 26); addAll.x = 8; addAll.y = 106;
    addAll.cornerRadius = 7; addAll.fills = solid(C.primary);
    card.appendChild(addAll);
    const addAllT = mkText('Add All to Cart', 10, 600, C.white);
    addAllT.x = (136 - addAllT.width) / 2; addAllT.y = 7;
    addAll.appendChild(addAllT);
  });

  // --- Section 2: Previously Bought ---
  const pbLbl = mkText('PREVIOUSLY BOUGHT', 10, 600, C.textMuted);
  pbLbl.x = 16; pbLbl.y = 260; s.appendChild(pbLbl);

  var prevItems = [
    { name: 'Fresh Cream 25%', variant: '500ml', price: '95', lastBought: '2 Jul' },
    { name: 'Dark Compound Choc', variant: '1kg', price: '380', trending: true, lastBought: '2 Jul' },
    { name: 'Cake Box 8 inch', variant: 'Pack of 10', price: '150', originalPrice: '180', lastBought: '24 Jun' },
    { name: 'Vanilla Essence', variant: '100ml', price: '65', lastBought: '24 Jun' },
    { name: 'Food Colour Set', variant: '12 colours', price: '340', lastBought: '17 Jun' },
    { name: 'Piping Bags 100', variant: 'Disposable', price: '120', lastBought: '17 Jun' },
  ];
  var TW3 = Math.floor((SW - 40) / 2);
  prevItems.forEach(function(p, i) {
    var col2 = i % 2, rowN = Math.floor(i / 2);
    var tileY = 276 + rowN * 186;
    if (tileY + 180 > SH - 80) return;

    const tile = figma.createFrame();
    tile.resize(TW3, 180); tile.x = 16 + col2 * (TW3 + 8); tile.y = tileY;
    tile.cornerRadius = 10; tile.fills = solid(C.bg);
    tile.strokes = [{ type: 'SOLID', color: C.border }]; tile.strokeWeight = 1;
    s.appendChild(tile);

    const img = mkImgBox(TW3, 96, '', 0);
    img.topLeftRadius = 10; img.topRightRadius = 10; tile.appendChild(img);
    if (p.trending) {
      const tb = mkBadge('Trending', C.amber, C.white);
      tb.x = 4; tb.y = 4; tile.appendChild(tb);
    }
    const name = mkText(p.name, 11, 600, C.text, TW3 - 10);
    name.x = 5; name.y = 100; tile.appendChild(name);
    const variant = mkText(p.variant, 9, 400, C.textMuted);
    variant.x = 5; variant.y = 114; tile.appendChild(variant);
    const pr = mkText('₹' + p.price, 13, 700, C.text);
    pr.x = 5; pr.y = 126; tile.appendChild(pr);
    const lbT = mkText('Last: ' + p.lastBought, 9, 400, C.textMuted);
    lbT.x = 5; lbT.y = 142; tile.appendChild(lbT);

    const btn = figma.createFrame();
    btn.resize(TW3 - 10, 26); btn.x = 5; btn.y = 148;
    btn.cornerRadius = 7; btn.fills = solid(C.primaryBg);
    btn.strokes = [{ type: 'SOLID', color: C.primary }]; btn.strokeWeight = 1;
    tile.appendChild(btn);
    const bt = mkText('+ Add to Cart', 10, 600, C.primary);
    bt.x = (TW3 - 10 - bt.width) / 2; bt.y = 6; btn.appendChild(bt);
  });

  s.appendChild(mkBottomNav('order-again'));
  figma.currentPage.appendChild(s);
  return s;
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 7 — Cart / Checkout
// ─────────────────────────────────────────────────────────────────────────────
function buildCheckoutScreen(col, row) {
  const s = mkScreen('07 · Cart — Checkout', col, row);

  // Header
  const hdr = figma.createFrame();
  hdr.resize(SW, 48); hdr.y = 0; hdr.fills = solid(C.bg); s.appendChild(hdr);
  const back = mkText('←', 20, 400, C.text);
  back.x = 16; back.y = 12; hdr.appendChild(back);
  const ht = mkText('Your Order', 15, 700, C.text);
  ht.x = (SW - ht.width) / 2; ht.y = 14; hdr.appendChild(ht);
  const itemsBadge = mkText('🛒  3 items', 12, 500, C.primary);
  itemsBadge.x = SW - 82; itemsBadge.y = 16; hdr.appendChild(itemsBadge);

  // Cart items section
  const cartLbl = mkText('ITEMS IN YOUR CART', 10, 600, C.textMuted);
  cartLbl.x = 16; cartLbl.y = 54; s.appendChild(cartLbl);

  var cartItems = [
    { name: 'Fresh Cream 25%', variant: '500ml · Ingredients', price: '₹95', op: '₹120', qty: 2 },
    { name: 'Dark Compound Chocolate', variant: '1kg · Cocoa & Chocolates', price: '₹380', qty: 1 },
    { name: 'Cake Box 8 inch', variant: 'Pack of 10 · Packaging', price: '₹150', op: '₹180', qty: 3 },
  ];
  var itemY = 70;
  cartItems.forEach(function(item, i) {
    const row2 = figma.createFrame();
    row2.resize(SW - 32, 68); row2.x = 16; row2.y = itemY;
    row2.cornerRadius = 8; row2.fills = solid(C.bg); s.appendChild(row2);

    const img = mkImgBox(52, 52, '', 8);
    img.x = 0; img.y = 8; row2.appendChild(img);
    const name = mkText(item.name, 12, 600, C.text, 160);
    name.x = 60; name.y = 8; row2.appendChild(name);
    const variant = mkText(item.variant, 10, 400, C.textMuted, 160);
    variant.x = 60; variant.y = 23; row2.appendChild(variant);
    const pr = mkText(item.price, 13, 700, C.text);
    pr.x = 60; pr.y = 38; row2.appendChild(pr);
    if (item.op) {
      const op = mkText(item.op, 10, 400, C.textMuted);
      op.x = 60 + pr.width + 6; op.y = 40; row2.appendChild(op);
      const sl = mkRect(op.width, 1, C.textMuted);
      sl.x = 60 + pr.width + 6; sl.y = 46; row2.appendChild(sl);
    }
    mkStepper(row2.width - 92, 22, item.qty, row2);
    if (i < cartItems.length - 1) mkDivider(SW - 32, 68, row2);
    itemY += 76;
  });

  // You Might Also Like
  var ymalY = itemY + 8;
  const ymalLbl = mkText('YOU MIGHT ALSO LIKE', 10, 600, C.textMuted);
  ymalLbl.x = 16; ymalLbl.y = ymalY; s.appendChild(ymalLbl);
  var ymProds = ['Vanilla Ess.', 'Parchmt Paper', 'Food Colours'];
  ymProds.forEach(function(yp, i) {
    const mt = figma.createFrame();
    mt.resize(100, 76); mt.x = 16 + i * 108; mt.y = ymalY + 16;
    mt.cornerRadius = 8; mt.fills = solid(C.surface); s.appendChild(mt);
    const mImg = mkImgBox(100, 52, '', 0);
    mImg.topLeftRadius = 8; mImg.topRightRadius = 8; mt.appendChild(mImg);
    const mn = mkText(yp, 10, 500, C.text, 92);
    mn.x = 4; mn.y = 56; mt.appendChild(mn);
  });

  // Bill Details
  var billY = ymalY + 104;
  const billLbl = mkText('BILL DETAILS', 10, 600, C.textMuted);
  billLbl.x = 16; billLbl.y = billY; s.appendChild(billLbl);

  const billCard = figma.createFrame();
  billCard.resize(SW - 32, 116); billCard.x = 16; billCard.y = billY + 14;
  billCard.cornerRadius = 12; billCard.fills = solid(C.surface); s.appendChild(billCard);

  var billRows = [
    { label: 'Item total', value: '₹1,040', color: C.textSub },
    { label: 'Discount (BAKE10)', value: '- ₹104', color: C.green },
    { label: 'Delivery charges', value: '₹49', color: C.textSub },
  ];
  billRows.forEach(function(br, i) {
    const bl = mkText(br.label, 12, 400, br.color);
    bl.x = 12; bl.y = 10 + i * 22; billCard.appendChild(bl);
    const bv = mkText(br.value, 12, 600, br.color);
    bv.x = billCard.width - 12 - bv.width; bv.y = 10 + i * 22; billCard.appendChild(bv);
  });
  mkDivider(SW - 56, 78, billCard);
  const tl = mkText('To pay', 14, 700, C.text);
  tl.x = 12; tl.y = 84; billCard.appendChild(tl);
  const tv = mkText('₹985', 16, 700, C.primary);
  tv.x = billCard.width - 12 - tv.width; tv.y = 82; billCard.appendChild(tv);

  // Discount code
  var discY = billY + 142;
  const discRow = figma.createFrame();
  discRow.resize(SW - 32, 44); discRow.x = 16; discRow.y = discY;
  discRow.cornerRadius = 10; discRow.fills = solid(C.bg);
  discRow.strokes = [{ type: 'SOLID', color: C.border }]; discRow.strokeWeight = 1;
  s.appendChild(discRow);
  const discPh = mkText('Enter discount code...', 12, 400, C.textMuted);
  discPh.x = 12; discPh.y = 14; discRow.appendChild(discPh);
  const applyBtn = figma.createFrame();
  applyBtn.resize(62, 32); applyBtn.x = discRow.width - 70; applyBtn.y = 6;
  applyBtn.cornerRadius = 8; applyBtn.fills = solid(C.primary);
  discRow.appendChild(applyBtn);
  const applyT = mkText('Apply', 12, 600, C.white);
  applyT.x = (62 - applyT.width) / 2; applyT.y = 8; applyBtn.appendChild(applyT);

  // Fixed CTA bar (2 rows, above bottom nav)
  const ctaBorder = mkRect(SW, 1, C.border);
  ctaBorder.y = SH - 80 - 80; s.appendChild(ctaBorder);
  const ctaBg = mkRect(SW, 80, C.bg);
  ctaBg.y = SH - 80 - 80; s.appendChild(ctaBg);

  // Row 1: Address
  const addrRow = figma.createFrame();
  addrRow.resize(SW - 32, 32); addrRow.x = 16; addrRow.y = SH - 80 - 74;
  addrRow.cornerRadius = 8; addrRow.fills = solid(C.surface); s.appendChild(addrRow);
  const addrT = mkText('📍  Home, 123 MG Road, Mumbai', 11, 500, C.text);
  addrT.x = 10; addrT.y = 9; addrRow.appendChild(addrT);
  const changeT = mkText('Change', 11, 600, C.primary);
  changeT.x = addrRow.width - 10 - changeT.width; changeT.y = 9; addrRow.appendChild(changeT);

  // Row 2: Payment + Proceed button
  const upiT = mkText('💳 UPI  ∧', 12, 500, C.textSub);
  upiT.x = 16; upiT.y = SH - 80 - 34; s.appendChild(upiT);

  const proceedBtn = figma.createFrame();
  proceedBtn.resize(144, 36); proceedBtn.x = SW - 16 - 144; proceedBtn.y = SH - 80 - 38;
  proceedBtn.cornerRadius = 10; proceedBtn.fills = solid(C.primary); s.appendChild(proceedBtn);
  const proceedT = mkText('Proceed  ₹985', 13, 700, C.white);
  proceedT.x = (144 - proceedT.width) / 2; proceedT.y = 10; proceedBtn.appendChild(proceedT);

  s.appendChild(mkBottomNav('cart'));
  figma.currentPage.appendChild(s);
  return s;
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 8 — Order Confirmation
// ─────────────────────────────────────────────────────────────────────────────
function buildOrderConfirmationScreen(col, row) {
  const s = mkScreen('08 · Order Confirmation', col, row);

  // Top amber section
  const topBg = mkRect(SW, 260, C.primaryBg);
  topBg.y = 0; s.appendChild(topBg);

  const successCircle = mkRect(80, 80, C.green, 40);
  successCircle.x = (SW - 80) / 2; successCircle.y = 90; s.appendChild(successCircle);
  const check = mkText('✓', 38, 700, C.white);
  check.x = (SW - check.width) / 2; check.y = 108; s.appendChild(check);

  const headline = mkText('Order Placed Successfully!', 20, 700, C.text);
  headline.x = (SW - headline.width) / 2; headline.y = 190; s.appendChild(headline);
  const sub = mkText('Thank you for ordering with Baker Ally', 13, 400, C.textSub);
  sub.x = (SW - sub.width) / 2; sub.y = 218; s.appendChild(sub);

  // Order details card
  const detailCard = figma.createFrame();
  detailCard.resize(SW - 32, 120); detailCard.x = 16; detailCard.y = 276;
  detailCard.cornerRadius = 14; detailCard.fills = solid(C.bg);
  detailCard.strokes = [{ type: 'SOLID', color: C.border }]; detailCard.strokeWeight = 1;
  s.appendChild(detailCard);

  var dRows = [
    { l: 'Order ID', v: 'ORD-3392' },
    { l: 'Total paid', v: '₹985' },
    { l: 'Payment', v: 'UPI' },
  ];
  dRows.forEach(function(dr, i) {
    const dl = mkText(dr.l, 13, 400, C.textSub);
    dl.x = 16; dl.y = 14 + i * 30; detailCard.appendChild(dl);
    const dv = mkText(dr.v, 13, 600, C.text);
    dv.x = detailCard.width - 16 - dv.width; dv.y = 14 + i * 30; detailCard.appendChild(dv);
    if (i < dRows.length - 1) mkDivider(detailCard.width - 32, 14 + i * 30 + 24, detailCard);
  });

  // WhatsApp banner
  const waBg = mkRect(SW - 32, 50, C.greenBg, 12);
  waBg.x = 16; waBg.y = 412; s.appendChild(waBg);
  const waT = mkText('📱  WhatsApp confirmation sent to +91 98765 43210', 12, 400, C.text, SW - 64);
  waT.x = 28; waT.y = 428; s.appendChild(waT);

  // Delivery estimate
  const delivT = mkText('Estimated delivery: 9 Jul – 11 Jul 2026', 13, 500, C.textSub);
  delivT.x = (SW - delivT.width) / 2; delivT.y = 476; s.appendChild(delivT);

  mkDivider(SW - 32, 502, s);

  // Two action buttons
  const trackBtn = figma.createFrame();
  trackBtn.resize((SW - 48) / 2, 48);
  trackBtn.x = 16; trackBtn.y = 514;
  trackBtn.cornerRadius = 12; trackBtn.fills = solid(C.bg);
  trackBtn.strokes = [{ type: 'SOLID', color: C.primary }]; trackBtn.strokeWeight = 1.5;
  s.appendChild(trackBtn);
  const trackT = mkText('Track Order', 14, 600, C.primary);
  trackT.x = (trackBtn.width - trackT.width) / 2; trackT.y = 15; trackBtn.appendChild(trackT);

  const shopBtn = figma.createFrame();
  shopBtn.resize((SW - 48) / 2, 48);
  shopBtn.x = 16 + (SW - 48) / 2 + 16; shopBtn.y = 514;
  shopBtn.cornerRadius = 12; shopBtn.fills = solid(C.primary); s.appendChild(shopBtn);
  const shopT = mkText('Continue Shopping', 13, 600, C.white);
  shopT.x = (shopBtn.width - shopT.width) / 2; shopT.y = 15; shopBtn.appendChild(shopT);

  s.appendChild(mkBottomNav('home'));
  figma.currentPage.appendChild(s);
  return s;
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 9 — Profile Overlay (Bottom Sheet)
// ─────────────────────────────────────────────────────────────────────────────
function buildProfileOverlay(col, row) {
  const s = mkScreen('09 · Profile Overlay (Bottom Sheet)', col, row);

  // Dimmed background
  const dim = figma.createRectangle();
  dim.resize(SW, SH); dim.x = 0; dim.y = 0;
  dim.fills = [{ type: 'SOLID', color: { r: 0, g: 0, b: 0 }, opacity: 0.45 }];
  s.appendChild(dim);

  // Sheet frame (90% of screen height)
  const SHEET_H = Math.round(SH * 0.9);
  const sheet = figma.createFrame();
  sheet.resize(SW, SHEET_H);
  sheet.x = 0; sheet.y = SH - SHEET_H;
  sheet.topLeftRadius = 20; sheet.topRightRadius = 20;
  sheet.fills = solid(C.bg);
  s.appendChild(sheet);

  // Drag handle
  const handle = mkRect(40, 4, C.border, 2);
  handle.x = (SW - 40) / 2; handle.y = 12; sheet.appendChild(handle);

  // Profile card at top of sheet
  const profileCard = figma.createFrame();
  profileCard.resize(SW - 32, 102);
  profileCard.x = 16; profileCard.y = 28;
  profileCard.cornerRadius = 14; profileCard.fills = solid(C.surface);
  sheet.appendChild(profileCard);

  const av = mkRect(60, 60, C.primary, 30);
  av.x = 12; av.y = 21; profileCard.appendChild(av);
  const avT = mkText('PS', 20, 700, C.white);
  avT.x = 22; avT.y = 31; profileCard.appendChild(avT);

  const uName = mkText('Priya Sharma', 15, 700, C.text);
  uName.x = 84; uName.y = 18; profileCard.appendChild(uName);
  const biz = mkText('Sunshine Cakes & Co.', 12, 400, C.textSub);
  biz.x = 84; biz.y = 38; profileCard.appendChild(biz);
  const phone = mkText('+91 98765 43210', 11, 400, C.textMuted);
  phone.x = 84; phone.y = 56; profileCard.appendChild(phone);
  const editT = mkText('Edit →', 11, 600, C.primary);
  editT.x = profileCard.width - 14 - editT.width; editT.y = 72; profileCard.appendChild(editT);

  // Menu list
  var menuItems = [
    { icon: '📦', label: 'Your Orders' },
    { icon: '🚚', label: 'Order Status' },
    { icon: '❤', label: 'Your Wishlist' },
    { icon: '🧾', label: 'Receipts & Invoices' },
    { icon: '📍', label: 'Delivery Addresses' },
    { icon: '🍰', label: 'Recipes' },
    { icon: '📞', label: 'Contact Us' },
    { icon: '?', label: 'Help & Support' },
  ];
  const ITEM_H = 50;
  const menuCard = figma.createFrame();
  menuCard.resize(SW - 32, menuItems.length * ITEM_H);
  menuCard.x = 16; menuCard.y = 144;
  menuCard.cornerRadius = 14; menuCard.fills = solid(C.bg);
  menuCard.strokes = [{ type: 'SOLID', color: C.border }]; menuCard.strokeWeight = 1;
  sheet.appendChild(menuCard);

  menuItems.forEach(function(item, i) {
    var ry = i * ITEM_H;
    const icon = mkText(item.icon, 18, 400, C.text);
    icon.x = 14; icon.y = ry + 14; menuCard.appendChild(icon);
    const lbl = mkText(item.label, 14, 500, C.text);
    lbl.x = 46; lbl.y = ry + 16; menuCard.appendChild(lbl);
    const arr = mkText('›', 20, 400, C.textMuted);
    arr.x = menuCard.width - 22; arr.y = ry + 12; menuCard.appendChild(arr);
    if (i < menuItems.length - 1) mkDivider(menuCard.width, ry + ITEM_H, menuCard);
  });

  // Log out button
  const logoutY = 144 + menuItems.length * ITEM_H + 16;
  const logoutBtn = figma.createFrame();
  logoutBtn.resize(SW - 32, 48);
  logoutBtn.x = 16; logoutBtn.y = logoutY;
  logoutBtn.cornerRadius = 14; logoutBtn.fills = solid(C.redBg);
  sheet.appendChild(logoutBtn);
  const logoutT = mkText('🚪  Log Out', 14, 600, C.red);
  logoutT.x = (SW - 32 - logoutT.width) / 2; logoutT.y = 14; logoutBtn.appendChild(logoutT);

  figma.currentPage.appendChild(s);
  return s;
}

// ─────────────────────────────────────────────────────────────────────────────
// ARCHITECTURE DIAGRAM
// Translates the Plan.md system architecture into a styled Figma diagram.
// Placed below the 3×3 screen grid, spanning the same total width (1330px).
//
// Tiers:
//   CLIENT  →  Supabase Auth  →  BACKEND  →  DATA + EXTERNAL SERVICES
//   + CI/CD strip at the bottom
// ─────────────────────────────────────────────────────────────────────────────
function buildArchitectureDiagram() {
  const DIAG_W = 1330;
  const DIAG_X = 0;
  const DIAG_Y = 3 * (SH + GAP) + GAP; // below all 9 screens
  const PAD = 16;
  const INNER_W = DIAG_W - PAD * 2;

  // Diagram-specific colour palette
  const DC = {
    clientBg:  { r: 0.937, g: 0.953, b: 1.000 }, // indigo-50
    clientBdr: { r: 0.298, g: 0.404, b: 0.929 }, // indigo-500
    authBg:    { r: 0.992, g: 0.957, b: 0.878 }, // amber wash (primary)
    authBdr:   C.primary,
    backBg:    { r: 0.961, g: 0.945, b: 1.000 }, // purple-50
    backBdr:   { r: 0.549, g: 0.216, b: 0.875 }, // purple-600
    dataBg:    { r: 0.925, g: 0.988, b: 0.961 }, // green-50
    dataBdr:   { r: 0.043, g: 0.588, b: 0.427 }, // green-600
    extBg:     { r: 1.000, g: 0.969, b: 0.925 }, // orange-50
    extBdr:    { r: 0.851, g: 0.506, b: 0.082 }, // amber-600
    cicdBg:    { r: 0.945, g: 0.945, b: 0.953 }, // gray-100
    cicdBdr:   { r: 0.576, g: 0.576, b: 0.604 }, // gray-500
    conn:      { r: 0.576, g: 0.576, b: 0.604 }, // connector arrows
    boxBg:     C.bg,
    boxBdr:    C.border,
  };

  // ── Root frame ─────────────────────────────────────────────────────────────
  const d = figma.createFrame();
  d.name = '10 · Architecture Diagram';
  d.resize(DIAG_W, 1200); // will be resized at end
  d.x = DIAG_X; d.y = DIAG_Y;
  d.fills = solid(C.bg);
  d.strokes = [{ type: 'SOLID', color: C.border }];
  d.strokeWeight = 1;
  d.cornerRadius = 16;
  d.clipsContent = false;

  // ── Shared helpers ─────────────────────────────────────────────────────────

  // Coloured tier container with label
  function mkTier(w, h, label, bg, bdr) {
    const f = figma.createFrame();
    f.resize(w, h);
    f.cornerRadius = 10;
    f.fills = solid(bg);
    f.strokes = [{ type: 'SOLID', color: bdr }];
    f.strokeWeight = 1.5;
    const lbl = mkText(label, 10, 700, bdr, w - 16);
    lbl.x = 14; lbl.y = 10;
    f.appendChild(lbl);
    return f;
  }

  // White inner service card with title + bullet lines
  function mkCard(w, h, title, lines, titleColor, bdr) {
    const f = figma.createFrame();
    f.resize(w, h);
    f.cornerRadius = 8;
    f.fills = solid(DC.boxBg);
    f.strokes = [{ type: 'SOLID', color: bdr || DC.boxBdr }];
    f.strokeWeight = 1;
    const t = mkText(title, 12, 700, titleColor || C.text);
    t.x = 12; t.y = 9; f.appendChild(t);
    var lineY = 28;
    lines.forEach(function(l) {
      if (l === '') { lineY += 6; return; }
      const lt = mkText(l, 11, 400, C.textSub, w - 24);
      lt.x = 12; lt.y = lineY; f.appendChild(lt);
      lineY += lt.height + 2;
    });
    return f;
  }

  // Vertical connector line + downward arrow
  function mkConnector(cx, y, h) {
    const line = mkRect(2, h, DC.conn);
    line.x = cx - 1; line.y = y; d.appendChild(line);
    const arr = mkText('▼', 12, 700, DC.conn);
    arr.x = cx - 6; arr.y = y + h - 14; d.appendChild(arr);
  }

  // ── Title ──────────────────────────────────────────────────────────────────
  var y = 24;
  const diagTitle = mkText('Baker Ally — System Architecture', 22, 700, C.text);
  diagTitle.x = (DIAG_W - diagTitle.width) / 2; diagTitle.y = y; d.appendChild(diagTitle);
  y += 32;
  const diagSub = mkText('Source: Planning docs/Initial plan/Plan.md  ·  July 2026', 12, 400, C.textMuted);
  diagSub.x = (DIAG_W - diagSub.width) / 2; diagSub.y = y; d.appendChild(diagSub);
  y += 36;

  // ── CLIENT TIER ────────────────────────────────────────────────────────────
  const clientTier = mkTier(INNER_W, 180, 'CLIENT TIER', DC.clientBg, DC.clientBdr);
  clientTier.x = PAD; clientTier.y = y; d.appendChild(clientTier);

  const flutterCard = mkCard(Math.floor(INNER_W / 2) - 24, 148,
    'Flutter App  (iOS + Android)',
    [
      'Customer only — zero admin code',
      'Browse · Cart · Pay · Track orders',
      '',
      'Riverpod · GoRouter · Dio · Drift',
      'razorpay_flutter · supabase_flutter (auth only)',
      'firebase_messaging · workmanager · app_links',
    ],
    DC.clientBdr, DC.clientBdr);
  flutterCard.x = 16; flutterCard.y = 24; clientTier.appendChild(flutterCard);

  const adminCard = mkCard(Math.floor(INNER_W / 2) - 24, 148,
    'Admin Web Panel  (Browser — Next.js 14)',
    [
      'shadcn/ui · Tailwind CSS · Hosted on Vercel',
      'Mobile-responsive for phone/tablet use',
      '',
      'Products · Categories · Pricing · Variants',
      'Orders · Discounts · Stock · Images',
      'Privilege levels · User management',
    ],
    DC.clientBdr, DC.clientBdr);
  adminCard.x = INNER_W - 16 - adminCard.width; adminCard.y = 24;
  clientTier.appendChild(adminCard);

  y += 180;

  // ── Auth connector + box ───────────────────────────────────────────────────
  mkConnector(DIAG_W / 2, y, 28);
  y += 28;

  const AUTH_W = 480;
  const authBox = figma.createFrame();
  authBox.resize(AUTH_W, 86);
  authBox.x = (DIAG_W - AUTH_W) / 2; authBox.y = y;
  authBox.cornerRadius = 10;
  authBox.fills = solid(DC.authBg);
  authBox.strokes = [{ type: 'SOLID', color: DC.authBdr }]; authBox.strokeWeight = 1.5;
  d.appendChild(authBox);

  const authTitle2 = mkText('Supabase Auth', 14, 700, C.primary);
  authTitle2.x = (AUTH_W - authTitle2.width) / 2; authTitle2.y = 10; authBox.appendChild(authTitle2);
  var authLines = [
    'OTP (phone) · Google OAuth · Apple Sign-In',
    'Issues signed JWT with role claim  ·  Stored in flutter_secure_storage',
  ];
  authLines.forEach(function(l, i) {
    const at = mkText(l, 11, 400, C.textSub, AUTH_W - 24);
    at.textAlignHorizontal = 'CENTER';
    at.x = 12; at.y = 32 + i * 18; authBox.appendChild(at);
  });

  y += 86;

  mkConnector(DIAG_W / 2, y, 28);
  const httpsT = mkText('HTTPS · Authorization: Bearer JWT', 11, 400, DC.conn);
  httpsT.x = DIAG_W / 2 + 8; httpsT.y = y + 7; d.appendChild(httpsT);
  y += 28;

  // ── BACKEND TIER ───────────────────────────────────────────────────────────
  const backendTier = mkTier(INNER_W, 288, 'BACKEND TIER — Supabase Edge Functions', DC.backBg, DC.backBdr);
  backendTier.x = PAD; backendTier.y = y; d.appendChild(backendTier);

  const honoT = mkText('Hono · Deno · TypeScript · Full NPM compatibility', 12, 500, C.textSub);
  honoT.x = 16; honoT.y = 26; backendTier.appendChild(honoT);

  // Middleware pipeline box
  const mwBox = figma.createFrame();
  mwBox.resize(INNER_W - 32, 80);
  mwBox.x = 16; mwBox.y = 48;
  mwBox.cornerRadius = 8; mwBox.fills = solid(DC.boxBg);
  mwBox.strokes = [{ type: 'SOLID', color: DC.backBdr }]; mwBox.strokeWeight = 1;
  backendTier.appendChild(mwBox);
  const mwTitle = mkText('Middleware Pipeline', 12, 700, C.text);
  mwTitle.x = 12; mwTitle.y = 8; mwBox.appendChild(mwTitle);
  var mwLines = [
    'authMiddleware   → verify Supabase JWT on every protected route',
    'adminMiddleware  → check role = \'admin\' in JWT claims',
    'Zod              → validate + type-check every incoming request body',
    'Drizzle ORM      → type-safe SQL queries · Supavisor pooler port 6543',
  ];
  mwLines.forEach(function(l, i) {
    const lt = mkText(l, 10, 400, C.textSub, INNER_W - 56);
    lt.x = 12; lt.y = 26 + i * 14; mwBox.appendChild(lt);
  });

  // API route columns
  var apiColW = Math.floor((INNER_W - 48) / 3);
  var apiCols = [
    { label: 'Public (no auth)', color: C.green, routes: ['GET /v1/categories', 'GET /v1/products', 'GET /v1/products/:id'] },
    { label: 'Customer  (JWT required)', color: C.blue, routes: ['GET /v1/orders/:id', 'POST /v1/cart/checkout', 'POST /v1/orders'] },
    { label: 'Admin  (JWT + role=admin)', color: C.red, routes: ['POST /v1/admin/products', 'PUT /v1/admin/products/:id', 'POST /v1/admin/discounts'] },
  ];
  apiCols.forEach(function(col, ci) {
    const colBox = figma.createFrame();
    colBox.resize(apiColW, 84);
    colBox.x = 16 + ci * (apiColW + 8); colBox.y = 138;
    colBox.cornerRadius = 6; colBox.fills = solid(DC.boxBg);
    colBox.strokes = [{ type: 'SOLID', color: DC.boxBdr }]; colBox.strokeWeight = 1;
    backendTier.appendChild(colBox);
    const colLbl = mkText(col.label, 10, 700, col.color);
    colLbl.x = 8; colLbl.y = 8; colBox.appendChild(colLbl);
    col.routes.forEach(function(r, ri) {
      const rt = mkText(r, 10, 400, C.textSub, apiColW - 16);
      rt.x = 8; rt.y = 24 + ri * 16; colBox.appendChild(rt);
    });
  });

  // Webhooks
  const wbBox = figma.createFrame();
  wbBox.resize(INNER_W - 32, 44);
  wbBox.x = 16; wbBox.y = 234;
  wbBox.cornerRadius = 6; wbBox.fills = solid(DC.boxBg);
  wbBox.strokes = [{ type: 'SOLID', color: DC.boxBdr }]; wbBox.strokeWeight = 1;
  backendTier.appendChild(wbBox);
  const wbTitle = mkText('Webhooks (inbound)  →  idempotency-checked via webhook_events table before processing', 11, 600, C.text, INNER_W - 56);
  wbTitle.x = 12; wbTitle.y = 8; wbBox.appendChild(wbTitle);
  var wbItems = [
    'POST /v1/webhooks/razorpay    ← Razorpay fires on payment events (payment.captured, payment.failed)',
    'POST /v1/webhooks/shiprocket  ← Shiprocket fires on shipment status changes (shipped, out for delivery, delivered)',
  ];
  wbItems.forEach(function(wbI, ii) {
    const wt = mkText(wbI, 10, 400, C.textSub, INNER_W - 56);
    wt.x = 12; wt.y = 22 + ii * 12; wbBox.appendChild(wt);
  });

  y += 288;

  // ── Split connectors ────────────────────────────────────────────────────────
  var CX_DATA = Math.round(PAD + INNER_W * 0.21);
  var CX_EXT  = Math.round(PAD + INNER_W * 0.73);
  mkConnector(CX_DATA, y, 36);
  const lLbl = mkText('SQL via Drizzle', 10, 500, DC.conn);
  lLbl.x = CX_DATA + 6; lLbl.y = y + 10; d.appendChild(lLbl);
  mkConnector(CX_EXT, y, 36);
  const rLbl = mkText('Outbound API calls', 10, 500, DC.conn);
  rLbl.x = CX_EXT - rLbl.width - 6; rLbl.y = y + 10; d.appendChild(rLbl);
  y += 40;

  // ── DATA TIER + EXTERNAL SERVICES (side by side) ──────────────────────────
  const BOTTOM_H = 310;
  const DATA_W   = Math.round(INNER_W * 0.39);
  const EXT_W    = INNER_W - DATA_W - 12;

  // Data Tier
  const dataTier = mkTier(DATA_W, BOTTOM_H, 'DATA TIER', DC.dataBg, DC.dataBdr);
  dataTier.x = PAD; dataTier.y = y; d.appendChild(dataTier);

  const pgCard = figma.createFrame();
  pgCard.resize(DATA_W - 32, 160);
  pgCard.x = 16; pgCard.y = 28;
  pgCard.cornerRadius = 8; pgCard.fills = solid(DC.boxBg);
  pgCard.strokes = [{ type: 'SOLID', color: DC.dataBdr }]; pgCard.strokeWeight = 1;
  dataTier.appendChild(pgCard);
  const pgTitle2 = mkText('Supabase PostgreSQL  (Pro plan)', 12, 700, C.text);
  pgTitle2.x = 12; pgTitle2.y = 9; pgCard.appendChild(pgTitle2);

  var tables = ['users', 'categories', 'sub_categories', 'products', 'product_variants', 'product_images', 'orders', 'order_items', 'carts / cart_items', 'addresses', 'shipments', 'discounts', 'wishlists', 'notifications', 'webhook_events', 'brownie_points'];
  var tColW = Math.floor((DATA_W - 56) / 3);
  tables.forEach(function(tbl, i) {
    var tc = Math.floor(i / 6);
    var tr = i % 6;
    const tT = mkText(tbl, 9, 400, C.textSub, tColW - 4);
    tT.x = 12 + tc * tColW; tT.y = 28 + tr * 14; pgCard.appendChild(tT);
  });

  const rlsNote = mkText('Supavisor pooler port 6543 · prepare: false · RLS + code-level ownership checks', 10, 400, C.textMuted, DATA_W - 44);
  rlsNote.x = 12; rlsNote.y = 140; pgCard.appendChild(rlsNote);

  const stCard = figma.createFrame();
  stCard.resize(DATA_W - 32, 100);
  stCard.x = 16; stCard.y = 200;
  stCard.cornerRadius = 8; stCard.fills = solid(DC.boxBg);
  stCard.strokes = [{ type: 'SOLID', color: DC.dataBdr }]; stCard.strokeWeight = 1;
  dataTier.appendChild(stCard);
  const stTitle2 = mkText('Supabase Storage', 12, 700, C.text);
  stTitle2.x = 12; stTitle2.y = 9; stCard.appendChild(stTitle2);
  var stLines = [
    'bucket: product-images (public)',
    'products/{id}/primary.webp · gallery/*.webp',
    'categories/{id}.webp · avatars/{user_id}.webp',
    'Admin uploads → Hono validates → converts to webp → stores URL in DB',
  ];
  stLines.forEach(function(l, i) {
    const lt = mkText(l, 10, 400, C.textSub, DATA_W - 44);
    lt.x = 12; lt.y = 26 + i * 16; stCard.appendChild(lt);
  });

  // External Services
  const extTier = mkTier(EXT_W, BOTTOM_H, 'EXTERNAL SERVICES', DC.extBg, DC.extBdr);
  extTier.x = PAD + DATA_W + 12; extTier.y = y; d.appendChild(extTier);

  var services = [
    { name: 'Razorpay  (Payments)', color: C.primary, lines: ['UPI (0% fee) · Debit/Credit cards · Netbanking · Wallets', 'razorpay npm SDK · HMAC-SHA256 signature verification', 'Webhook → /v1/webhooks/razorpay · idempotency via razorpay_payment_id UNIQUE'] },
    { name: 'Shiprocket  (Pan-India Shipping)', color: C.blue, lines: ['Aggregates BlueDart · Delhivery · Ecom Express · 25+ carriers', 'Backend creates shipment after order confirmed · AWB stored in shipments table', 'Webhook → /v1/webhooks/shiprocket · updates order status + triggers WhatsApp'] },
    { name: 'Interakt  (WhatsApp Business API)', color: C.green, lines: ['Pre-approved template messages via Meta', 'Triggers: order confirmed · shipped · out for delivery · delivered'] },
    { name: 'Firebase FCM  (Push notifications)', color: C.amber, lines: ['firebase-admin Node SDK · device token stored in users table', 'Order status changes + admin-initiated promotions'] },
    { name: 'Resend  (Transactional Email)', color: DC.cicdBdr, lines: ['Configured as Supabase Auth SMTP — zero custom code required', 'OTP · Magic link · Password reset · Email verification'] },
  ];

  var svcY = 26;
  services.forEach(function(svc) {
    var svcH = 18 + svc.lines.length * 16 + 8;
    const svcBox = figma.createFrame();
    svcBox.resize(EXT_W - 32, svcH);
    svcBox.x = 16; svcBox.y = svcY;
    svcBox.cornerRadius = 7; svcBox.fills = solid(DC.boxBg);
    svcBox.strokes = [{ type: 'SOLID', color: DC.extBdr }]; svcBox.strokeWeight = 1;
    extTier.appendChild(svcBox);
    const st = mkText(svc.name, 12, 700, svc.color);
    st.x = 10; st.y = 8; svcBox.appendChild(st);
    svc.lines.forEach(function(l, li) {
      const lt = mkText(l, 10, 400, C.textSub, EXT_W - 56);
      lt.x = 10; lt.y = 24 + li * 15; svcBox.appendChild(lt);
    });
    svcY += svcH + 6;
  });

  y += BOTTOM_H;

  // ── CI/CD strip ────────────────────────────────────────────────────────────
  y += 12;
  const cicdTier = mkTier(INNER_W, 80, 'CI / CD', DC.cicdBg, DC.cicdBdr);
  cicdTier.x = PAD; cicdTier.y = y; d.appendChild(cicdTier);
  var cicdItems = [
    'Flutter app (iOS + Android)   →   Codemagic   →   App Store + Play Store',
    'Admin web (Next.js)           →   Vercel       →   auto-deploy on git push to main',
    'DB schema changes             →   Supabase CLI migrations   →   run before backend deploy',
  ];
  cicdItems.forEach(function(item, i) {
    const it = mkText(item, 11, 400, C.textSub, INNER_W - 48);
    it.x = 14; it.y = 26 + i * 17; cicdTier.appendChild(it);
  });
  y += 80;

  // Resize to exact content height
  d.resize(DIAG_W, y + PAD * 2);

  figma.currentPage.appendChild(d);
  return d;
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────────────────────
async function main() {
  // All fonts must be loaded before any mkText() call
  await Promise.all([
    figma.loadFontAsync({ family: 'Inter', style: 'Regular' }),
    figma.loadFontAsync({ family: 'Inter', style: 'Medium' }),
    figma.loadFontAsync({ family: 'Inter', style: 'Semi Bold' }),
    figma.loadFontAsync({ family: 'Inter', style: 'Bold' }),
  ]);

  var screens = [];

  // Row 0 — Auth + Home + Catalog overview
  screens.push(buildLoginScreen(0, 0));
  screens.push(buildHomeScreen(1, 0));
  screens.push(buildCatalogL1Screen(2, 0));

  // Row 1 — Catalog drill-down + Product detail + Order Again
  screens.push(buildCatalogL2Screen(0, 1));
  screens.push(buildProductDetailScreen(1, 1));
  screens.push(buildOrderAgainScreen(2, 1));

  // Row 2 — Checkout flow + Profile
  screens.push(buildCheckoutScreen(0, 2));
  screens.push(buildOrderConfirmationScreen(1, 2));
  screens.push(buildProfileOverlay(2, 2));

  // Architecture diagram — placed below all 9 screens
  screens.push(buildArchitectureDiagram());

  figma.viewport.scrollAndZoomIntoView(screens);
  figma.closePlugin('Baker Ally: 9 screens + architecture diagram generated!');
}

main();

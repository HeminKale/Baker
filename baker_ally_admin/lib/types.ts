export type Role = "admin" | "staff" | "customer_individual";

export type AdminUser = {
  id: string;
  email: string | null;
  phone: string | null;
  fullName: string | null;
  businessName: string | null;
  gstin: string | null;
  avatarUrl: string | null;
  fcmToken: string | null;
  roleId: string;
  privilegeLevelId: string | null;
  isActive: boolean;
  createdAt: string;
};

export type MeResponse = {
  data: { user: AdminUser; role: Role };
};

export type Category = {
  id: string;
  name: string;
  imageUrl: string | null;
  sortOrder: number;
  isActive: boolean;
  createdAt: string;
};

export type SubCategory = {
  id: string;
  categoryId: string;
  name: string;
  imageUrl: string | null;
  sortOrder: number;
  isActive: boolean;
  createdAt: string;
};

export type Product = {
  id: string;
  subCategoryId: string;
  name: string;
  description: string | null;
  isActive: boolean;
  isTrending: boolean;
  sortOrder: number;
  createdAt: string;
  updatedAt: string;
};

export type ProductVariant = {
  id: string;
  productId: string;
  name: string;
  sku: string;
  originalPrice: number;
  currentPrice: number;
  stockQty: number;
  isActive: boolean;
  sortOrder: number;
  createdAt: string;
};

export type ProductImage = {
  id: string;
  productId: string;
  variantId: string | null;
  storagePath: string;
  publicUrl: string;
  sortOrder: number;
  isPrimary: boolean;
  createdAt: string;
};

export type ProductDetail = Product & {
  subCategoryName: string;
  categoryName: string;
  variants: ProductVariant[];
  images: ProductImage[];
};

export type DiscountType = "percent" | "flat" | "free_shipping";

export type Discount = {
  id: string;
  code: string | null;
  name: string;
  type: DiscountType;
  value: number;
  minOrderValue: number;
  maxUses: number | null;
  usesCount: number;
  isActive: boolean;
  startsAt: string | null;
  expiresAt: string | null;
  createdAt: string;
};

export type OrderStatus = "pending" | "confirmed" | "processing" | "shipped" | "delivered" | "cancelled";

export type Order = {
  id: string;
  userId: string;
  addressId: string;
  status: OrderStatus;
  subtotal: number;
  discountId: string | null;
  discountValue: number;
  shippingCost: number;
  total: number;
  razorpayOrderId: string | null;
  razorpayPaymentId: string | null;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
  customerName: string;
};

export type OrderItem = {
  id: string;
  orderId: string;
  variantId: string;
  productName: string;
  variantName: string;
  quantity: number;
  unitPrice: number;
  createdAt: string;
};

export type Address = {
  id: string;
  userId: string;
  label: string | null;
  line1: string;
  line2: string | null;
  city: string;
  state: string;
  pincode: string;
  isDefault: boolean;
  createdAt: string;
};

export type OrderDetail = Order & {
  customerEmail: string | null;
  customerPhone: string | null;
  items: OrderItem[];
  address: Address | null;
};

export type AdminOrStaffUser = AdminUser & { role: "admin" | "staff" };

export type CrossSellLink = {
  id: string;
  recommendedProductId: string;
  recommendedProductName: string;
  sortOrder: number;
};

export type WishlistInsightRow = {
  variantId: string;
  wishlistCount: number;
  variantName: string;
  stockQty: number;
  productId: string;
  productName: string;
};

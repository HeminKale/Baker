import type { Role } from "./types";

export type NavItem = {
  href: string;
  label: string;
  roles: Role[];
};

export const NAV_ITEMS: NavItem[] = [
  { href: "/", label: "Dashboard", roles: ["admin", "staff"] },
  { href: "/categories", label: "Categories", roles: ["admin", "staff"] },
  { href: "/products", label: "Products", roles: ["admin", "staff"] },
  { href: "/insights/wishlist", label: "Wishlist Insights", roles: ["admin", "staff"] },
  { href: "/orders", label: "Orders", roles: ["admin", "staff"] },
  { href: "/discounts", label: "Discounts", roles: ["admin"] },
  { href: "/users", label: "Users", roles: ["admin"] },
];

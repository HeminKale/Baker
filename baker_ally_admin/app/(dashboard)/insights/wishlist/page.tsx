import Link from "next/link";
import { apiFetch } from "@/lib/api";
import type { WishlistInsightRow } from "@/lib/types";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";

export default async function WishlistInsightsPage() {
  const res = await apiFetch<{ data: WishlistInsightRow[] }>("/v1/admin/wishlist-insights?limit=50");

  return (
    <div className="flex flex-col gap-4">
      <h1 className="text-xl font-semibold">Wishlist insights</h1>
      <p className="text-sm text-muted-foreground">
        Most-wishlisted variants, highest demand first. Out-of-stock items near the top are worth restocking —
        wishlisting them is also how customers ask to be notified when they're back.
      </p>
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Product</TableHead>
            <TableHead>Variant</TableHead>
            <TableHead>Wishlisted by</TableHead>
            <TableHead>Stock</TableHead>
            <TableHead className="w-1" />
          </TableRow>
        </TableHeader>
        <TableBody>
          {res.data.map((row) => (
            <TableRow key={row.variantId}>
              <TableCell>{row.productName}</TableCell>
              <TableCell>{row.variantName}</TableCell>
              <TableCell>{row.wishlistCount}</TableCell>
              <TableCell>
                {row.stockQty > 0 ? (
                  <Badge>{row.stockQty} in stock</Badge>
                ) : (
                  <Badge variant="destructive">Out of stock</Badge>
                )}
              </TableCell>
              <TableCell>
                <Link href={`/products/${row.productId}`} className="text-sm text-primary hover:underline">
                  View product
                </Link>
              </TableCell>
            </TableRow>
          ))}
          {res.data.length === 0 && (
            <TableRow>
              <TableCell colSpan={5} className="text-center text-muted-foreground">
                No wishlist activity yet
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </div>
  );
}

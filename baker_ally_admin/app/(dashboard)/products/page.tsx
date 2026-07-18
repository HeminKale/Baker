import Link from "next/link";
import { apiFetch } from "@/lib/api";
import type { Category, Product, SubCategory } from "@/lib/types";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { ProductFilters } from "./product-filters";
import { ProductsPagination } from "./products-pagination";

type SearchParams = Promise<{
  categoryId?: string;
  subCategoryId?: string;
  q?: string;
  active?: string;
  page?: string;
}>;

export default async function ProductsPage({ searchParams }: { searchParams: SearchParams }) {
  const params = await searchParams;
  const page = Number(params.page ?? "1") || 1;

  const query = new URLSearchParams();
  if (params.categoryId) query.set("categoryId", params.categoryId);
  if (params.subCategoryId) query.set("subCategoryId", params.subCategoryId);
  if (params.q) query.set("q", params.q);
  if (params.active) query.set("active", params.active);
  query.set("page", String(page));
  query.set("limit", "20");

  const [productsRes, categoriesRes, subCategoriesRes] = await Promise.all([
    apiFetch<{ data: Product[]; meta: { page: number; limit: number; total: number } }>(
      `/v1/admin/products?${query.toString()}`,
    ),
    apiFetch<{ data: Category[] }>("/v1/admin/categories"),
    apiFetch<{ data: SubCategory[] }>("/v1/admin/sub-categories"),
  ]);

  const subCategoryById = new Map(subCategoriesRes.data.map((s) => [s.id, s]));
  const totalPages = Math.max(1, Math.ceil(productsRes.meta.total / productsRes.meta.limit));

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-semibold">Products</h1>
        <Button render={<Link href="/products/new" />}>Add product</Button>
      </div>

      <ProductFilters categories={categoriesRes.data} subCategories={subCategoriesRes.data} />

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Name</TableHead>
            <TableHead>Sub-category</TableHead>
            <TableHead>Trending</TableHead>
            <TableHead>Status</TableHead>
            <TableHead className="w-1" />
          </TableRow>
        </TableHeader>
        <TableBody>
          {productsRes.data.map((product) => (
            <TableRow key={product.id}>
              <TableCell>{product.name}</TableCell>
              <TableCell>{subCategoryById.get(product.subCategoryId)?.name ?? "-"}</TableCell>
              <TableCell>{product.isTrending ? <Badge>Trending</Badge> : null}</TableCell>
              <TableCell>
                <Badge variant={product.isActive ? "default" : "secondary"}>
                  {product.isActive ? "Active" : "Inactive"}
                </Badge>
              </TableCell>
              <TableCell>
                <Button variant="ghost" size="sm" render={<Link href={`/products/${product.id}`} />}>
                  Edit
                </Button>
              </TableCell>
            </TableRow>
          ))}
          {productsRes.data.length === 0 && (
            <TableRow>
              <TableCell colSpan={5} className="text-center text-muted-foreground">
                No products found
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>

      <ProductsPagination page={page} totalPages={totalPages} />
    </div>
  );
}

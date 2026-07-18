import { apiFetch } from "@/lib/api";
import type { Category, SubCategory } from "@/lib/types";
import { NewProductForm } from "./new-product-form";

export default async function NewProductPage() {
  const [categoriesRes, subCategoriesRes] = await Promise.all([
    apiFetch<{ data: Category[] }>("/v1/admin/categories"),
    apiFetch<{ data: SubCategory[] }>("/v1/admin/sub-categories"),
  ]);

  return (
    <div className="flex flex-col gap-4">
      <h1 className="text-xl font-semibold">Add product</h1>
      <NewProductForm categories={categoriesRes.data} subCategories={subCategoriesRes.data} />
    </div>
  );
}

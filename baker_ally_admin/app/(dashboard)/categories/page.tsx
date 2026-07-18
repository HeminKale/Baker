import { apiFetch } from "@/lib/api";
import type { Category, SubCategory } from "@/lib/types";
import { CategoriesManager } from "./categories-client";

export default async function CategoriesPage() {
  const [categoriesRes, subCategoriesRes] = await Promise.all([
    apiFetch<{ data: Category[] }>("/v1/admin/categories"),
    apiFetch<{ data: SubCategory[] }>("/v1/admin/sub-categories"),
  ]);

  return (
    <CategoriesManager initialCategories={categoriesRes.data} initialSubCategories={subCategoriesRes.data} />
  );
}

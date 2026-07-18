import { notFound } from "next/navigation";
import { apiFetch, ApiError } from "@/lib/api";
import type { Category, CrossSellLink, ProductDetail, SubCategory } from "@/lib/types";
import { ProductInfoForm } from "./product-info-form";
import { VariantsSection } from "./variants-section";
import { ImagesSection } from "./images-section";
import { CrossSellSection } from "./cross-sell-section";

export default async function ProductDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  let product: ProductDetail;
  try {
    const res = await apiFetch<{ data: ProductDetail }>(`/v1/admin/products/${id}`);
    product = res.data;
  } catch (err) {
    if (err instanceof ApiError && err.status === 404) notFound();
    throw err;
  }

  const [categoriesRes, subCategoriesRes, crossSellRes] = await Promise.all([
    apiFetch<{ data: Category[] }>("/v1/admin/categories"),
    apiFetch<{ data: SubCategory[] }>("/v1/admin/sub-categories"),
    apiFetch<{ data: CrossSellLink[] }>(`/v1/admin/products/${id}/cross-sell`),
  ]);

  return (
    <div className="flex flex-col gap-6">
      <h1 className="text-xl font-semibold">{product.name}</h1>
      <ProductInfoForm product={product} categories={categoriesRes.data} subCategories={subCategoriesRes.data} />
      <VariantsSection productId={product.id} variants={product.variants} />
      <ImagesSection productId={product.id} images={product.images} variants={product.variants} />
      <CrossSellSection productId={product.id} links={crossSellRes.data} />
    </div>
  );
}

import { notFound } from "next/navigation";
import { requireAdmin } from "@/lib/auth";
import { apiFetch, ApiError } from "@/lib/api";
import type { Discount } from "@/lib/types";
import { DiscountForm } from "../discount-form";

export default async function EditDiscountPage({ params }: { params: Promise<{ id: string }> }) {
  await requireAdmin();
  const { id } = await params;

  let discount: Discount | undefined;
  try {
    const res = await apiFetch<{ data: Discount[] }>("/v1/admin/discounts");
    discount = res.data.find((d) => d.id === id);
  } catch (err) {
    if (err instanceof ApiError && err.status === 404) notFound();
    throw err;
  }
  if (!discount) notFound();

  return (
    <div className="flex flex-col gap-4">
      <h1 className="text-xl font-semibold">Edit discount</h1>
      <DiscountForm discount={discount} />
    </div>
  );
}

import { requireAdmin } from "@/lib/auth";
import { DiscountForm } from "../discount-form";

export default async function NewDiscountPage() {
  await requireAdmin();

  return (
    <div className="flex flex-col gap-4">
      <h1 className="text-xl font-semibold">Add discount</h1>
      <DiscountForm />
    </div>
  );
}

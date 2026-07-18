"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { apiFetchClient, ApiError } from "@/lib/api-client";
import type { OrderStatus } from "@/lib/types";
import { Button } from "@/components/ui/button";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";

const ALLOWED_TRANSITIONS: Partial<Record<OrderStatus, OrderStatus[]>> = {
  confirmed: ["processing", "cancelled"],
  processing: ["shipped", "cancelled"],
  shipped: ["delivered"],
};

const LABELS: Record<OrderStatus, string> = {
  pending: "Pending",
  confirmed: "Confirmed",
  processing: "Mark processing",
  shipped: "Mark shipped",
  delivered: "Mark delivered",
  cancelled: "Cancel order",
};

export function StatusControl({ orderId, status }: { orderId: string; status: OrderStatus }) {
  const router = useRouter();
  const [saving, setSaving] = useState<OrderStatus | null>(null);
  const [confirmCancel, setConfirmCancel] = useState(false);

  const nextOptions = ALLOWED_TRANSITIONS[status] ?? [];

  async function applyStatus(newStatus: OrderStatus) {
    setSaving(newStatus);
    try {
      await apiFetchClient(`/v1/admin/orders/${orderId}/status`, {
        method: "PATCH",
        body: JSON.stringify({ status: newStatus }),
      });
      toast.success(`Order ${newStatus}`);
      router.refresh();
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : "Something went wrong");
    } finally {
      setSaving(null);
      setConfirmCancel(false);
    }
  }

  if (nextOptions.length === 0) {
    return <p className="text-sm text-muted-foreground">No further status changes available for this order.</p>;
  }

  return (
    <div className="flex flex-wrap items-center gap-2">
      {nextOptions
        .filter((s) => s !== "cancelled")
        .map((s) => (
          <Button key={s} disabled={saving !== null} onClick={() => applyStatus(s)}>
            {saving === s ? "Saving..." : LABELS[s]}
          </Button>
        ))}

      {nextOptions.includes("cancelled") && (
        <AlertDialog open={confirmCancel} onOpenChange={setConfirmCancel}>
          <Button variant="destructive" disabled={saving !== null} onClick={() => setConfirmCancel(true)}>
            Cancel order
          </Button>
          <AlertDialogContent>
            <AlertDialogHeader>
              <AlertDialogTitle>Cancel this order?</AlertDialogTitle>
              <AlertDialogDescription>
                This restocks every item in the order and cannot be undone. The customer keeps their payment
                refund handled separately (outside this panel).
              </AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel>Keep order</AlertDialogCancel>
              <AlertDialogAction
                variant="destructive"
                disabled={saving !== null}
                onClick={() => applyStatus("cancelled")}
              >
                {saving === "cancelled" ? "Cancelling..." : "Cancel order"}
              </AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>
      )}
    </div>
  );
}

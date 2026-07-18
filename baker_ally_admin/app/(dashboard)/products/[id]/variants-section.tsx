"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { apiFetchClient, ApiError } from "@/lib/api-client";
import type { ProductVariant } from "@/lib/types";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

function rupees(paise: number) {
  return `₹${(paise / 100).toFixed(0)}`;
}

export function VariantsSection({ productId, variants }: { productId: string; variants: ProductVariant[] }) {
  const router = useRouter();
  const [dialog, setDialog] = useState<ProductVariant | "new" | null>(null);
  const [stockDrafts, setStockDrafts] = useState<Record<string, string>>({});
  const [savingStock, setSavingStock] = useState<string | null>(null);

  async function handleStockSave(variantId: string) {
    const draft = stockDrafts[variantId];
    const stockQty = Number(draft);
    if (!Number.isInteger(stockQty) || stockQty < 0) {
      toast.error("Stock must be a non-negative whole number");
      return;
    }
    setSavingStock(variantId);
    try {
      await apiFetchClient(`/v1/admin/variants/${variantId}/stock`, {
        method: "PATCH",
        body: JSON.stringify({ stockQty }),
      });
      toast.success("Stock updated");
      router.refresh();
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : "Something went wrong");
    } finally {
      setSavingStock(null);
    }
  }

  return (
    <Card>
      <CardHeader className="flex-row items-center justify-between">
        <CardTitle>Variants</CardTitle>
        <Button size="sm" onClick={() => setDialog("new")}>
          Add variant
        </Button>
      </CardHeader>
      <CardContent>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Name</TableHead>
              <TableHead>SKU</TableHead>
              <TableHead>MRP</TableHead>
              <TableHead>Price</TableHead>
              <TableHead>Stock</TableHead>
              <TableHead>Status</TableHead>
              <TableHead className="w-1" />
            </TableRow>
          </TableHeader>
          <TableBody>
            {variants.map((v) => (
              <TableRow key={v.id}>
                <TableCell>{v.name}</TableCell>
                <TableCell className="font-mono text-xs">{v.sku}</TableCell>
                <TableCell>{rupees(v.originalPrice)}</TableCell>
                <TableCell>{rupees(v.currentPrice)}</TableCell>
                <TableCell>
                  <div className="flex items-center gap-1">
                    <Input
                      type="number"
                      min={0}
                      className="w-20"
                      value={stockDrafts[v.id] ?? String(v.stockQty)}
                      onChange={(e) => setStockDrafts((prev) => ({ ...prev, [v.id]: e.target.value }))}
                    />
                    <Button
                      size="sm"
                      variant="outline"
                      disabled={savingStock === v.id || stockDrafts[v.id] === undefined}
                      onClick={() => handleStockSave(v.id)}
                    >
                      Update
                    </Button>
                  </div>
                </TableCell>
                <TableCell>
                  <Badge variant={v.isActive ? "default" : "secondary"}>{v.isActive ? "Active" : "Inactive"}</Badge>
                </TableCell>
                <TableCell>
                  <Button variant="ghost" size="sm" onClick={() => setDialog(v)}>
                    Edit
                  </Button>
                </TableCell>
              </TableRow>
            ))}
            {variants.length === 0 && (
              <TableRow>
                <TableCell colSpan={7} className="text-center text-muted-foreground">
                  No variants yet
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </CardContent>

      {dialog && <VariantDialog productId={productId} value={dialog} onClose={() => setDialog(null)} />}
    </Card>
  );
}

function VariantDialog({
  productId,
  value,
  onClose,
}: {
  productId: string;
  value: ProductVariant | "new";
  onClose: () => void;
}) {
  const router = useRouter();
  const isNew = value === "new";
  const [name, setName] = useState(isNew ? "" : value.name);
  const [sku, setSku] = useState(isNew ? "" : value.sku);
  const [originalPrice, setOriginalPrice] = useState(isNew ? "" : String(value.originalPrice / 100));
  const [currentPrice, setCurrentPrice] = useState(isNew ? "" : String(value.currentPrice / 100));
  const [isActive, setIsActive] = useState(isNew ? true : value.isActive);
  const [saving, setSaving] = useState(false);

  async function handleSave() {
    const originalPaise = Math.round(Number(originalPrice) * 100);
    const currentPaise = Math.round(Number(currentPrice) * 100);
    if (!Number.isFinite(originalPaise) || !Number.isFinite(currentPaise)) {
      toast.error("Enter valid prices");
      return;
    }
    setSaving(true);
    try {
      if (isNew) {
        await apiFetchClient(`/v1/admin/products/${productId}/variants`, {
          method: "POST",
          body: JSON.stringify({
            name,
            sku,
            originalPrice: originalPaise,
            currentPrice: currentPaise,
            isActive,
          }),
        });
        toast.success("Variant created");
      } else {
        await apiFetchClient(`/v1/admin/variants/${value.id}`, {
          method: "PUT",
          body: JSON.stringify({
            name,
            sku,
            originalPrice: originalPaise,
            currentPrice: currentPaise,
            isActive,
          }),
        });
        toast.success("Variant updated");
      }
      router.refresh();
      onClose();
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : "Something went wrong");
    } finally {
      setSaving(false);
    }
  }

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{isNew ? "Add variant" : "Edit variant"}</DialogTitle>
        </DialogHeader>
        <div className="flex flex-col gap-4">
          <div className="flex flex-col gap-2">
            <Label htmlFor="v-name">Name</Label>
            <Input id="v-name" placeholder="500g" value={name} onChange={(e) => setName(e.target.value)} />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="v-sku">SKU</Label>
            <Input id="v-sku" value={sku} onChange={(e) => setSku(e.target.value)} />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div className="flex flex-col gap-2">
              <Label htmlFor="v-mrp">MRP (₹)</Label>
              <Input
                id="v-mrp"
                type="number"
                min={0}
                value={originalPrice}
                onChange={(e) => setOriginalPrice(e.target.value)}
              />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="v-price">Selling price (₹)</Label>
              <Input
                id="v-price"
                type="number"
                min={0}
                value={currentPrice}
                onChange={(e) => setCurrentPrice(e.target.value)}
              />
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Switch id="v-active" checked={isActive} onCheckedChange={setIsActive} />
            <Label htmlFor="v-active">Active</Label>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button onClick={handleSave} disabled={saving || !name.trim() || !sku.trim()}>
            {saving ? "Saving..." : "Save"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { apiFetchClient, ApiError } from "@/lib/api-client";
import type { Discount, DiscountType } from "@/lib/types";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Card, CardContent } from "@/components/ui/card";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

// datetime-local <input> wants "YYYY-MM-DDTHH:mm"; the API wants full ISO.
function toLocalInputValue(iso: string | null) {
  if (!iso) return "";
  const d = new Date(iso);
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

export function DiscountForm({ discount }: { discount?: Discount }) {
  const router = useRouter();
  const isNew = !discount;
  const [code, setCode] = useState(discount?.code ?? "");
  const [name, setName] = useState(discount?.name ?? "");
  const [type, setType] = useState<DiscountType>(discount?.type ?? "percent");
  const [value, setValue] = useState(
    discount ? (discount.type === "flat" ? String(discount.value / 100) : String(discount.value)) : "",
  );
  const [minOrderValue, setMinOrderValue] = useState(
    discount ? String(discount.minOrderValue / 100) : "0",
  );
  const [maxUses, setMaxUses] = useState(discount?.maxUses ? String(discount.maxUses) : "");
  const [isActive, setIsActive] = useState(discount?.isActive ?? true);
  const [startsAt, setStartsAt] = useState(toLocalInputValue(discount?.startsAt ?? null));
  const [expiresAt, setExpiresAt] = useState(toLocalInputValue(discount?.expiresAt ?? null));
  const [saving, setSaving] = useState(false);

  async function handleSave() {
    setSaving(true);
    try {
      const numericValue = type === "free_shipping" ? 0 : type === "flat" ? Math.round(Number(value) * 100) : Number(value);
      const body = {
        code: code.trim() || undefined,
        name,
        type,
        value: numericValue,
        minOrderValue: Math.round(Number(minOrderValue || "0") * 100),
        maxUses: maxUses ? Number(maxUses) : undefined,
        isActive,
        startsAt: startsAt ? new Date(startsAt).toISOString() : undefined,
        expiresAt: expiresAt ? new Date(expiresAt).toISOString() : undefined,
      };

      if (isNew) {
        await apiFetchClient("/v1/admin/discounts", { method: "POST", body: JSON.stringify(body) });
        toast.success("Discount created");
        router.push("/discounts");
      } else {
        await apiFetchClient(`/v1/admin/discounts/${discount.id}`, { method: "PUT", body: JSON.stringify(body) });
        toast.success("Discount updated");
        router.refresh();
      }
    } catch (err) {
      if (err instanceof ApiError && err.code === "DUPLICATE_CODE") {
        toast.error("That code is already in use");
      } else {
        toast.error(err instanceof ApiError ? err.message : "Something went wrong");
      }
    } finally {
      setSaving(false);
    }
  }

  return (
    <Card className="max-w-lg">
      <CardContent>
        <div className="flex flex-col gap-4">
          <div className="flex flex-col gap-2">
            <Label htmlFor="d-code">Code</Label>
            <Input
              id="d-code"
              placeholder="BAKE10"
              value={code}
              onChange={(e) => setCode(e.target.value.toUpperCase())}
            />
          </div>

          <div className="flex flex-col gap-2">
            <Label htmlFor="d-name">Name</Label>
            <Input id="d-name" value={name} onChange={(e) => setName(e.target.value)} required />
          </div>

          <div className="flex flex-col gap-2">
            <Label htmlFor="d-type">Type</Label>
            <Select value={type} onValueChange={(v) => setType(v as DiscountType)}>
              <SelectTrigger id="d-type">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="percent">Percent off</SelectItem>
                <SelectItem value="flat">Flat amount off</SelectItem>
                <SelectItem value="free_shipping">Free shipping</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {type !== "free_shipping" && (
            <div className="flex flex-col gap-2">
              <Label htmlFor="d-value">{type === "percent" ? "Percent off" : "Amount off (₹)"}</Label>
              <Input id="d-value" type="number" min={0} value={value} onChange={(e) => setValue(e.target.value)} />
            </div>
          )}

          <div className="flex flex-col gap-2">
            <Label htmlFor="d-min">Minimum order value (₹)</Label>
            <Input
              id="d-min"
              type="number"
              min={0}
              value={minOrderValue}
              onChange={(e) => setMinOrderValue(e.target.value)}
            />
          </div>

          <div className="flex flex-col gap-2">
            <Label htmlFor="d-max">Max uses (blank = unlimited)</Label>
            <Input id="d-max" type="number" min={1} value={maxUses} onChange={(e) => setMaxUses(e.target.value)} />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="flex flex-col gap-2">
              <Label htmlFor="d-starts">Starts at</Label>
              <Input
                id="d-starts"
                type="datetime-local"
                value={startsAt}
                onChange={(e) => setStartsAt(e.target.value)}
              />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="d-expires">Expires at</Label>
              <Input
                id="d-expires"
                type="datetime-local"
                value={expiresAt}
                onChange={(e) => setExpiresAt(e.target.value)}
              />
            </div>
          </div>

          <div className="flex items-center gap-2">
            <Switch id="d-active" checked={isActive} onCheckedChange={setIsActive} />
            <Label htmlFor="d-active">Active</Label>
          </div>

          <Button onClick={handleSave} disabled={saving || !name.trim()} className="mt-2">
            {saving ? "Saving..." : isNew ? "Create discount" : "Save changes"}
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

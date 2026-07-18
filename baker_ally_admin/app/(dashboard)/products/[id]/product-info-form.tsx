"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { apiFetchClient, ApiError } from "@/lib/api-client";
import type { Category, ProductDetail, SubCategory } from "@/lib/types";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

export function ProductInfoForm({
  product,
  categories,
  subCategories,
}: {
  product: ProductDetail;
  categories: Category[];
  subCategories: SubCategory[];
}) {
  const router = useRouter();
  const initialCategoryId = subCategories.find((s) => s.id === product.subCategoryId)?.categoryId ?? "";
  const [categoryId, setCategoryId] = useState(initialCategoryId);
  const [subCategoryId, setSubCategoryId] = useState(product.subCategoryId);
  const [name, setName] = useState(product.name);
  const [description, setDescription] = useState(product.description ?? "");
  const [isActive, setIsActive] = useState(product.isActive);
  const [isTrending, setIsTrending] = useState(product.isTrending);
  const [saving, setSaving] = useState(false);

  const filteredSubCategories = subCategories.filter((s) => s.categoryId === categoryId);

  async function handleSave() {
    setSaving(true);
    try {
      await apiFetchClient(`/v1/admin/products/${product.id}`, {
        method: "PUT",
        body: JSON.stringify({
          subCategoryId,
          name,
          description: description || undefined,
          isActive,
          isTrending,
        }),
      });
      toast.success("Product saved");
      router.refresh();
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : "Something went wrong");
    } finally {
      setSaving(false);
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Product details</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="flex flex-col gap-4 max-w-lg">
          <div className="flex flex-col gap-2">
            <Label htmlFor="pi-category">Category</Label>
            <Select
              value={categoryId}
              onValueChange={(v) => {
                setCategoryId(String(v));
                setSubCategoryId("");
              }}
            >
              <SelectTrigger id="pi-category">
                <SelectValue placeholder="Select a category" />
              </SelectTrigger>
              <SelectContent>
                {categories.map((cat) => (
                  <SelectItem key={cat.id} value={cat.id}>
                    {cat.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="flex flex-col gap-2">
            <Label htmlFor="pi-subcategory">Sub-category</Label>
            <Select value={subCategoryId} onValueChange={(v) => setSubCategoryId(String(v))}>
              <SelectTrigger id="pi-subcategory">
                <SelectValue placeholder="Select a sub-category" />
              </SelectTrigger>
              <SelectContent>
                {filteredSubCategories.map((sub) => (
                  <SelectItem key={sub.id} value={sub.id}>
                    {sub.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="flex flex-col gap-2">
            <Label htmlFor="pi-name">Name</Label>
            <Input id="pi-name" value={name} onChange={(e) => setName(e.target.value)} required />
          </div>

          <div className="flex flex-col gap-2">
            <Label htmlFor="pi-description">Description</Label>
            <Textarea id="pi-description" value={description} onChange={(e) => setDescription(e.target.value)} />
          </div>

          <div className="flex items-center gap-2">
            <Switch id="pi-active" checked={isActive} onCheckedChange={setIsActive} />
            <Label htmlFor="pi-active">Active</Label>
          </div>

          <div className="flex items-center gap-2">
            <Switch id="pi-trending" checked={isTrending} onCheckedChange={setIsTrending} />
            <Label htmlFor="pi-trending">Trending</Label>
          </div>

          <Button onClick={handleSave} disabled={saving || !name.trim() || !subCategoryId} className="mt-2 self-start">
            {saving ? "Saving..." : "Save changes"}
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

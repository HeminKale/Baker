"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { apiFetchClient, ApiError } from "@/lib/api-client";
import type { Category, Product, SubCategory } from "@/lib/types";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Card, CardContent } from "@/components/ui/card";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

export function NewProductForm({
  categories,
  subCategories,
}: {
  categories: Category[];
  subCategories: SubCategory[];
}) {
  const router = useRouter();
  const [categoryId, setCategoryId] = useState(categories[0]?.id ?? "");
  const [subCategoryId, setSubCategoryId] = useState("");
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [isActive, setIsActive] = useState(true);
  const [isTrending, setIsTrending] = useState(false);
  const [saving, setSaving] = useState(false);

  const filteredSubCategories = subCategories.filter((s) => s.categoryId === categoryId);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!subCategoryId) {
      toast.error("Select a sub-category");
      return;
    }
    setSaving(true);
    try {
      const res = await apiFetchClient<{ data: Product }>("/v1/admin/products", {
        method: "POST",
        body: JSON.stringify({
          subCategoryId,
          name,
          description: description || undefined,
          isActive,
          isTrending,
        }),
      });
      toast.success("Product created");
      router.push(`/products/${res.data.id}`);
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : "Something went wrong");
    } finally {
      setSaving(false);
    }
  }

  return (
    <Card className="max-w-lg">
      <CardContent>
        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <div className="flex flex-col gap-2">
            <Label htmlFor="p-category">Category</Label>
            <Select
              value={categoryId}
              onValueChange={(v) => {
                setCategoryId(String(v));
                setSubCategoryId("");
              }}
            >
              <SelectTrigger id="p-category">
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
            <Label htmlFor="p-subcategory">Sub-category</Label>
            <Select value={subCategoryId} onValueChange={(v) => setSubCategoryId(String(v))}>
              <SelectTrigger id="p-subcategory">
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
            <Label htmlFor="p-name">Name</Label>
            <Input id="p-name" value={name} onChange={(e) => setName(e.target.value)} required />
          </div>

          <div className="flex flex-col gap-2">
            <Label htmlFor="p-description">Description</Label>
            <Textarea id="p-description" value={description} onChange={(e) => setDescription(e.target.value)} />
          </div>

          <div className="flex items-center gap-2">
            <Switch id="p-active" checked={isActive} onCheckedChange={setIsActive} />
            <Label htmlFor="p-active">Active</Label>
          </div>

          <div className="flex items-center gap-2">
            <Switch id="p-trending" checked={isTrending} onCheckedChange={setIsTrending} />
            <Label htmlFor="p-trending">Trending</Label>
          </div>

          <Button type="submit" disabled={saving || !name.trim() || !subCategoryId} className="mt-2">
            {saving ? "Creating..." : "Create product"}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}

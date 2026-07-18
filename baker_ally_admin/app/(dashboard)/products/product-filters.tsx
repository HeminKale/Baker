"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { useState } from "react";
import type { Category, SubCategory } from "@/lib/types";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

const ALL = "__all__";

export function ProductFilters({
  categories,
  subCategories,
}: {
  categories: Category[];
  subCategories: SubCategory[];
}) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [q, setQ] = useState(searchParams.get("q") ?? "");

  function updateParam(key: string, value: string | null) {
    const next = new URLSearchParams(searchParams.toString());
    if (value && value !== ALL) {
      next.set(key, value);
    } else {
      next.delete(key);
    }
    next.delete("page");
    router.push(`/products?${next.toString()}`);
  }

  function handleSearchSubmit(e: React.FormEvent) {
    e.preventDefault();
    updateParam("q", q || null);
  }

  const categoryId = searchParams.get("categoryId") ?? ALL;
  const subCategoryId = searchParams.get("subCategoryId") ?? ALL;
  const active = searchParams.get("active") ?? ALL;

  const filteredSubCategories = categoryId === ALL
    ? subCategories
    : subCategories.filter((s) => s.categoryId === categoryId);

  return (
    <div className="flex flex-wrap items-center gap-2">
      <form onSubmit={handleSearchSubmit} className="flex items-center gap-2">
        <Input
          placeholder="Search products..."
          value={q}
          onChange={(e) => setQ(e.target.value)}
          className="w-48"
        />
      </form>

      <Select value={categoryId} onValueChange={(v) => updateParam("categoryId", v === ALL ? null : String(v))}>
        <SelectTrigger className="w-40">
          <SelectValue placeholder="Category" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value={ALL}>All categories</SelectItem>
          {categories.map((cat) => (
            <SelectItem key={cat.id} value={cat.id}>
              {cat.name}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>

      <Select
        value={subCategoryId}
        onValueChange={(v) => updateParam("subCategoryId", v === ALL ? null : String(v))}
      >
        <SelectTrigger className="w-44">
          <SelectValue placeholder="Sub-category" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value={ALL}>All sub-categories</SelectItem>
          {filteredSubCategories.map((sub) => (
            <SelectItem key={sub.id} value={sub.id}>
              {sub.name}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>

      <Select value={active} onValueChange={(v) => updateParam("active", v === ALL ? null : String(v))}>
        <SelectTrigger className="w-32">
          <SelectValue placeholder="Status" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value={ALL}>All statuses</SelectItem>
          <SelectItem value="true">Active</SelectItem>
          <SelectItem value="false">Inactive</SelectItem>
        </SelectContent>
      </Select>
    </div>
  );
}

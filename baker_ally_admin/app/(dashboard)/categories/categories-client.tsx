"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { apiFetchClient, ApiError } from "@/lib/api-client";
import type { Category, SubCategory } from "@/lib/types";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";

export function CategoriesManager({
  initialCategories,
  initialSubCategories,
}: {
  initialCategories: Category[];
  initialSubCategories: SubCategory[];
}) {
  const [categoryDialog, setCategoryDialog] = useState<Category | "new" | null>(null);
  const [subCategoryDialog, setSubCategoryDialog] = useState<SubCategory | "new" | null>(null);

  return (
    <div className="flex flex-col gap-8">
      <section className="flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-semibold">Categories</h1>
          <Button onClick={() => setCategoryDialog("new")}>Add category</Button>
        </div>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Name</TableHead>
              <TableHead>Sort order</TableHead>
              <TableHead>Status</TableHead>
              <TableHead className="w-1" />
            </TableRow>
          </TableHeader>
          <TableBody>
            {initialCategories.map((cat) => (
              <TableRow key={cat.id}>
                <TableCell>{cat.name}</TableCell>
                <TableCell>{cat.sortOrder}</TableCell>
                <TableCell>
                  <Badge variant={cat.isActive ? "default" : "secondary"}>
                    {cat.isActive ? "Active" : "Inactive"}
                  </Badge>
                </TableCell>
                <TableCell>
                  <Button variant="ghost" size="sm" onClick={() => setCategoryDialog(cat)}>
                    Edit
                  </Button>
                </TableCell>
              </TableRow>
            ))}
            {initialCategories.length === 0 && (
              <TableRow>
                <TableCell colSpan={4} className="text-center text-muted-foreground">
                  No categories yet
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </section>

      <section className="flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-semibold">Sub-categories</h2>
          <Button onClick={() => setSubCategoryDialog("new")} disabled={initialCategories.length === 0}>
            Add sub-category
          </Button>
        </div>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Name</TableHead>
              <TableHead>Category</TableHead>
              <TableHead>Sort order</TableHead>
              <TableHead>Status</TableHead>
              <TableHead className="w-1" />
            </TableRow>
          </TableHeader>
          <TableBody>
            {initialSubCategories.map((sub) => (
              <TableRow key={sub.id}>
                <TableCell>{sub.name}</TableCell>
                <TableCell>{initialCategories.find((c) => c.id === sub.categoryId)?.name ?? "-"}</TableCell>
                <TableCell>{sub.sortOrder}</TableCell>
                <TableCell>
                  <Badge variant={sub.isActive ? "default" : "secondary"}>
                    {sub.isActive ? "Active" : "Inactive"}
                  </Badge>
                </TableCell>
                <TableCell>
                  <Button variant="ghost" size="sm" onClick={() => setSubCategoryDialog(sub)}>
                    Edit
                  </Button>
                </TableCell>
              </TableRow>
            ))}
            {initialSubCategories.length === 0 && (
              <TableRow>
                <TableCell colSpan={5} className="text-center text-muted-foreground">
                  No sub-categories yet
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </section>

      {categoryDialog && (
        <CategoryDialog value={categoryDialog} onClose={() => setCategoryDialog(null)} />
      )}
      {subCategoryDialog && (
        <SubCategoryDialog
          value={subCategoryDialog}
          categories={initialCategories}
          onClose={() => setSubCategoryDialog(null)}
        />
      )}
    </div>
  );
}

function CategoryDialog({ value, onClose }: { value: Category | "new"; onClose: () => void }) {
  const router = useRouter();
  const isNew = value === "new";
  const [name, setName] = useState(isNew ? "" : value.name);
  const [sortOrder, setSortOrder] = useState(isNew ? 0 : value.sortOrder);
  const [isActive, setIsActive] = useState(isNew ? true : value.isActive);
  const [saving, setSaving] = useState(false);

  async function handleSave() {
    setSaving(true);
    try {
      if (isNew) {
        await apiFetchClient("/v1/admin/categories", {
          method: "POST",
          body: JSON.stringify({ name, sortOrder, isActive }),
        });
        toast.success("Category created");
      } else {
        await apiFetchClient(`/v1/admin/categories/${value.id}`, {
          method: "PUT",
          body: JSON.stringify({ name, sortOrder, isActive }),
        });
        toast.success("Category updated");
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
          <DialogTitle>{isNew ? "Add category" : "Edit category"}</DialogTitle>
        </DialogHeader>
        <div className="flex flex-col gap-4">
          <div className="flex flex-col gap-2">
            <Label htmlFor="cat-name">Name</Label>
            <Input id="cat-name" value={name} onChange={(e) => setName(e.target.value)} />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="cat-sort">Sort order</Label>
            <Input
              id="cat-sort"
              type="number"
              value={sortOrder}
              onChange={(e) => setSortOrder(Number(e.target.value))}
            />
          </div>
          <div className="flex items-center gap-2">
            <Switch id="cat-active" checked={isActive} onCheckedChange={setIsActive} />
            <Label htmlFor="cat-active">Active</Label>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button onClick={handleSave} disabled={saving || !name.trim()}>
            {saving ? "Saving..." : "Save"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

function SubCategoryDialog({
  value,
  categories,
  onClose,
}: {
  value: SubCategory | "new";
  categories: Category[];
  onClose: () => void;
}) {
  const router = useRouter();
  const isNew = value === "new";
  const [categoryId, setCategoryId] = useState(isNew ? categories[0]?.id ?? "" : value.categoryId);
  const [name, setName] = useState(isNew ? "" : value.name);
  const [sortOrder, setSortOrder] = useState(isNew ? 0 : value.sortOrder);
  const [isActive, setIsActive] = useState(isNew ? true : value.isActive);
  const [saving, setSaving] = useState(false);

  async function handleSave() {
    setSaving(true);
    try {
      if (isNew) {
        await apiFetchClient("/v1/admin/sub-categories", {
          method: "POST",
          body: JSON.stringify({ categoryId, name, sortOrder, isActive }),
        });
        toast.success("Sub-category created");
      } else {
        await apiFetchClient(`/v1/admin/sub-categories/${value.id}`, {
          method: "PUT",
          body: JSON.stringify({ categoryId, name, sortOrder, isActive }),
        });
        toast.success("Sub-category updated");
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
          <DialogTitle>{isNew ? "Add sub-category" : "Edit sub-category"}</DialogTitle>
        </DialogHeader>
        <div className="flex flex-col gap-4">
          <div className="flex flex-col gap-2">
            <Label htmlFor="sub-category">Category</Label>
            <Select value={categoryId} onValueChange={(v) => setCategoryId(String(v))}>
              <SelectTrigger id="sub-category">
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
            <Label htmlFor="sub-name">Name</Label>
            <Input id="sub-name" value={name} onChange={(e) => setName(e.target.value)} />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="sub-sort">Sort order</Label>
            <Input
              id="sub-sort"
              type="number"
              value={sortOrder}
              onChange={(e) => setSortOrder(Number(e.target.value))}
            />
          </div>
          <div className="flex items-center gap-2">
            <Switch id="sub-active" checked={isActive} onCheckedChange={setIsActive} />
            <Label htmlFor="sub-active">Active</Label>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button onClick={handleSave} disabled={saving || !name.trim() || !categoryId}>
            {saving ? "Saving..." : "Save"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

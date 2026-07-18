"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import Image from "next/image";
import { apiFetchClient, ApiError } from "@/lib/api-client";
import type { ProductImage, ProductVariant } from "@/lib/types";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

const ALL_VARIANTS = "__all__";

export function ImagesSection({
  productId,
  images,
  variants,
}: {
  productId: string;
  images: ProductImage[];
  variants: ProductVariant[];
}) {
  const router = useRouter();
  const [file, setFile] = useState<File | null>(null);
  const [variantId, setVariantId] = useState(ALL_VARIANTS);
  const [isPrimary, setIsPrimary] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [deletingId, setDeletingId] = useState<string | null>(null);

  async function handleUpload() {
    if (!file) return;
    setUploading(true);
    try {
      const formData = new FormData();
      formData.append("file", file);
      if (variantId !== ALL_VARIANTS) formData.append("variantId", variantId);
      formData.append("isPrimary", String(isPrimary));

      await apiFetchClient(`/v1/admin/products/${productId}/images`, {
        method: "POST",
        body: formData,
      });
      toast.success("Image uploaded");
      setFile(null);
      setIsPrimary(false);
      router.refresh();
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : "Upload failed");
    } finally {
      setUploading(false);
    }
  }

  async function handleDelete(imgId: string) {
    setDeletingId(imgId);
    try {
      await apiFetchClient(`/v1/admin/products/${productId}/images/${imgId}`, { method: "DELETE" });
      toast.success("Image deleted");
      router.refresh();
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : "Something went wrong");
    } finally {
      setDeletingId(null);
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Images</CardTitle>
      </CardHeader>
      <CardContent className="flex flex-col gap-4">
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
          {images.map((img) => (
            <div key={img.id} className="flex flex-col gap-1">
              <div className="relative aspect-square overflow-hidden rounded-md border">
                <Image src={img.publicUrl} alt="" fill className="object-cover" unoptimized />
                {img.isPrimary && <Badge className="absolute top-1 left-1">Primary</Badge>}
              </div>
              <Button
                variant="ghost"
                size="sm"
                disabled={deletingId === img.id}
                onClick={() => handleDelete(img.id)}
              >
                Delete
              </Button>
            </div>
          ))}
          {images.length === 0 && <p className="col-span-full text-sm text-muted-foreground">No images yet</p>}
        </div>

        <div className="flex flex-wrap items-end gap-3 border-t pt-4">
          <div className="flex flex-col gap-2">
            <Label htmlFor="img-file">Upload image</Label>
            <input
              id="img-file"
              type="file"
              accept="image/*"
              onChange={(e) => setFile(e.target.files?.[0] ?? null)}
              className="text-sm"
            />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="img-variant">Variant (optional)</Label>
            <Select value={variantId} onValueChange={(v) => setVariantId(String(v))}>
              <SelectTrigger id="img-variant" className="w-40">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value={ALL_VARIANTS}>All variants</SelectItem>
                {variants.map((v) => (
                  <SelectItem key={v.id} value={v.id}>
                    {v.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="flex items-center gap-2 pb-2">
            <Checkbox id="img-primary" checked={isPrimary} onCheckedChange={(v) => setIsPrimary(v === true)} />
            <Label htmlFor="img-primary">Set as primary</Label>
          </div>
          <Button onClick={handleUpload} disabled={!file || uploading}>
            {uploading ? "Uploading..." : "Upload"}
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

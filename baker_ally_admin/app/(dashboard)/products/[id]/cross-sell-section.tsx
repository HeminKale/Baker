"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { apiFetchClient, ApiError } from "@/lib/api-client";
import type { CrossSellLink, Product } from "@/lib/types";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";

export function CrossSellSection({ productId, links }: { productId: string; links: CrossSellLink[] }) {
  const router = useRouter();
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<Product[]>([]);
  const [searching, setSearching] = useState(false);
  const [addingId, setAddingId] = useState<string | null>(null);
  const [removingId, setRemovingId] = useState<string | null>(null);

  const linkedIds = new Set(links.map((l) => l.recommendedProductId));

  async function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    if (!query.trim()) return;
    setSearching(true);
    try {
      const res = await apiFetchClient<{ data: Product[] }>(
        `/v1/admin/products?q=${encodeURIComponent(query)}&limit=10&active=true`,
      );
      setResults(res.data.filter((p) => p.id !== productId));
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : "Search failed");
    } finally {
      setSearching(false);
    }
  }

  async function handleAdd(recommendedProductId: string) {
    setAddingId(recommendedProductId);
    try {
      await apiFetchClient(`/v1/admin/products/${productId}/cross-sell`, {
        method: "POST",
        body: JSON.stringify({ recommendedProductId, sortOrder: links.length }),
      });
      toast.success("Added");
      router.refresh();
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : "Something went wrong");
    } finally {
      setAddingId(null);
    }
  }

  async function handleRemove(linkId: string) {
    setRemovingId(linkId);
    try {
      await apiFetchClient(`/v1/admin/products/${productId}/cross-sell/${linkId}`, { method: "DELETE" });
      toast.success("Removed");
      router.refresh();
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : "Something went wrong");
    } finally {
      setRemovingId(null);
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Cross-sell ("You Might Also Like")</CardTitle>
      </CardHeader>
      <CardContent className="flex flex-col gap-4">
        <p className="text-sm text-muted-foreground">
          Curated picks take positions 5-7 of this product&apos;s recommendation list; the rest stays
          algorithmic. Reorder by removing and re-adding in the order you want.
        </p>

        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Product</TableHead>
              <TableHead>Sort order</TableHead>
              <TableHead className="w-1" />
            </TableRow>
          </TableHeader>
          <TableBody>
            {links.map((link) => (
              <TableRow key={link.id}>
                <TableCell>{link.recommendedProductName}</TableCell>
                <TableCell>{link.sortOrder}</TableCell>
                <TableCell>
                  <Button
                    variant="ghost"
                    size="sm"
                    disabled={removingId === link.id}
                    onClick={() => handleRemove(link.id)}
                  >
                    Remove
                  </Button>
                </TableCell>
              </TableRow>
            ))}
            {links.length === 0 && (
              <TableRow>
                <TableCell colSpan={3} className="text-center text-muted-foreground">
                  No curated picks yet -- positions 5-7 fall back to algorithmic
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>

        <form onSubmit={handleSearch} className="flex items-end gap-2 border-t pt-4">
          <Input
            placeholder="Search products to add..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            className="w-64"
          />
          <Button type="submit" variant="outline" disabled={searching || !query.trim()}>
            {searching ? "Searching..." : "Search"}
          </Button>
        </form>

        {results.length > 0 && (
          <div className="flex flex-col gap-1">
            {results.map((p) => (
              <div key={p.id} className="flex items-center justify-between rounded-md border px-3 py-2 text-sm">
                <span>{p.name}</span>
                <Button
                  size="sm"
                  disabled={linkedIds.has(p.id) || addingId === p.id}
                  onClick={() => handleAdd(p.id)}
                >
                  {linkedIds.has(p.id) ? "Already added" : addingId === p.id ? "Adding..." : "Add"}
                </Button>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

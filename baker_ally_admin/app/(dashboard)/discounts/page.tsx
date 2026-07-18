import Link from "next/link";
import { requireAdmin } from "@/lib/auth";
import { apiFetch } from "@/lib/api";
import type { Discount } from "@/lib/types";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";

function formatValue(discount: Discount) {
  if (discount.type === "percent") return `${discount.value}%`;
  if (discount.type === "flat") return `₹${(discount.value / 100).toFixed(0)}`;
  return "Free shipping";
}

export default async function DiscountsPage() {
  await requireAdmin();
  const res = await apiFetch<{ data: Discount[] }>("/v1/admin/discounts");

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-semibold">Discounts</h1>
        <Button render={<Link href="/discounts/new" />}>Add discount</Button>
      </div>
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Code</TableHead>
            <TableHead>Name</TableHead>
            <TableHead>Type</TableHead>
            <TableHead>Value</TableHead>
            <TableHead>Uses</TableHead>
            <TableHead>Status</TableHead>
            <TableHead className="w-1" />
          </TableRow>
        </TableHeader>
        <TableBody>
          {res.data.map((discount) => (
            <TableRow key={discount.id}>
              <TableCell className="font-mono text-xs">{discount.code ?? "(auto-applied)"}</TableCell>
              <TableCell>{discount.name}</TableCell>
              <TableCell className="capitalize">{discount.type.replace("_", " ")}</TableCell>
              <TableCell>{formatValue(discount)}</TableCell>
              <TableCell>
                {discount.usesCount}
                {discount.maxUses ? ` / ${discount.maxUses}` : ""}
              </TableCell>
              <TableCell>
                <Badge variant={discount.isActive ? "default" : "secondary"}>
                  {discount.isActive ? "Active" : "Inactive"}
                </Badge>
              </TableCell>
              <TableCell>
                <Button variant="ghost" size="sm" render={<Link href={`/discounts/${discount.id}`} />}>
                  Edit
                </Button>
              </TableCell>
            </TableRow>
          ))}
          {res.data.length === 0 && (
            <TableRow>
              <TableCell colSpan={7} className="text-center text-muted-foreground">
                No discounts yet
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </div>
  );
}

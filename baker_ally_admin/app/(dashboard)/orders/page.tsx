import Link from "next/link";
import { apiFetch } from "@/lib/api";
import type { Order } from "@/lib/types";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { OrderFilters } from "./order-filters";
import { OrdersPagination } from "./orders-pagination";

type SearchParams = Promise<{ status?: string; q?: string; page?: string }>;

function rupees(paise: number) {
  return `₹${(paise / 100).toFixed(0)}`;
}

function statusVariant(status: string): "default" | "secondary" | "destructive" {
  if (status === "cancelled") return "destructive";
  if (status === "delivered") return "default";
  return "secondary";
}

export default async function OrdersPage({ searchParams }: { searchParams: SearchParams }) {
  const params = await searchParams;
  const page = Number(params.page ?? "1") || 1;

  const query = new URLSearchParams();
  if (params.status) query.set("status", params.status);
  if (params.q) query.set("q", params.q);
  query.set("page", String(page));
  query.set("limit", "20");

  const res = await apiFetch<{ data: Order[]; meta: { page: number; limit: number; total: number } }>(
    `/v1/admin/orders?${query.toString()}`,
  );
  const totalPages = Math.max(1, Math.ceil(res.meta.total / res.meta.limit));

  return (
    <div className="flex flex-col gap-4">
      <h1 className="text-xl font-semibold">Orders</h1>
      <OrderFilters />
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Customer</TableHead>
            <TableHead>Total</TableHead>
            <TableHead>Status</TableHead>
            <TableHead>Placed</TableHead>
            <TableHead className="w-1" />
          </TableRow>
        </TableHeader>
        <TableBody>
          {res.data.map((order) => (
            <TableRow key={order.id}>
              <TableCell>{order.customerName}</TableCell>
              <TableCell>{rupees(order.total)}</TableCell>
              <TableCell>
                <Badge variant={statusVariant(order.status)} className="capitalize">
                  {order.status}
                </Badge>
              </TableCell>
              <TableCell>{new Date(order.createdAt).toLocaleDateString()}</TableCell>
              <TableCell>
                <Link href={`/orders/${order.id}`} className="text-sm text-primary hover:underline">
                  View
                </Link>
              </TableCell>
            </TableRow>
          ))}
          {res.data.length === 0 && (
            <TableRow>
              <TableCell colSpan={5} className="text-center text-muted-foreground">
                No orders found
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
      <OrdersPagination page={page} totalPages={totalPages} />
    </div>
  );
}

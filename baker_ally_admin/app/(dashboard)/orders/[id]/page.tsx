import { notFound } from "next/navigation";
import { apiFetch, ApiError } from "@/lib/api";
import type { OrderDetail } from "@/lib/types";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { StatusControl } from "./status-control";

function rupees(paise: number) {
  return `₹${(paise / 100).toFixed(0)}`;
}

export default async function OrderDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  let order: OrderDetail;
  try {
    const res = await apiFetch<{ data: OrderDetail }>(`/v1/admin/orders/${id}`);
    order = res.data;
  } catch (err) {
    if (err instanceof ApiError && err.status === 404) notFound();
    throw err;
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold">Order {order.id.slice(0, 8)}</h1>
          <p className="text-sm text-muted-foreground">
            Placed {new Date(order.createdAt).toLocaleString()}
          </p>
        </div>
        <Badge className="capitalize text-sm">{order.status}</Badge>
      </div>

      <StatusControl orderId={order.id} status={order.status} />

      <div className="grid gap-6 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Customer</CardTitle>
          </CardHeader>
          <CardContent className="flex flex-col gap-1 text-sm">
            <span>{order.customerName}</span>
            {order.customerEmail && <span className="text-muted-foreground">{order.customerEmail}</span>}
            {order.customerPhone && <span className="text-muted-foreground">{order.customerPhone}</span>}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Delivery address</CardTitle>
          </CardHeader>
          <CardContent className="text-sm text-muted-foreground">
            {order.address ? (
              <>
                {order.address.label && <div className="text-foreground">{order.address.label}</div>}
                <div>{order.address.line1}</div>
                {order.address.line2 && <div>{order.address.line2}</div>}
                <div>
                  {order.address.city}, {order.address.state} {order.address.pincode}
                </div>
              </>
            ) : (
              "No address on file"
            )}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Items</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Product</TableHead>
                <TableHead>Variant</TableHead>
                <TableHead>Qty</TableHead>
                <TableHead>Unit price</TableHead>
                <TableHead>Line total</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {order.items.map((item) => (
                <TableRow key={item.id}>
                  <TableCell>{item.productName}</TableCell>
                  <TableCell>{item.variantName}</TableCell>
                  <TableCell>{item.quantity}</TableCell>
                  <TableCell>{rupees(item.unitPrice)}</TableCell>
                  <TableCell>{rupees(item.unitPrice * item.quantity)}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>

          <div className="mt-4 flex flex-col items-end gap-1 text-sm">
            <div className="flex w-48 justify-between">
              <span className="text-muted-foreground">Subtotal</span>
              <span>{rupees(order.subtotal)}</span>
            </div>
            {order.discountValue > 0 && (
              <div className="flex w-48 justify-between">
                <span className="text-muted-foreground">Discount</span>
                <span>-{rupees(order.discountValue)}</span>
              </div>
            )}
            <div className="flex w-48 justify-between">
              <span className="text-muted-foreground">Shipping</span>
              <span>{rupees(order.shippingCost)}</span>
            </div>
            <div className="flex w-48 justify-between font-semibold">
              <span>Total</span>
              <span>{rupees(order.total)}</span>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

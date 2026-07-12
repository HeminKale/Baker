import { PDFDocument, rgb, StandardFonts } from "pdf-lib";

import type { addresses, orderItems, orders } from "../db/schema.ts";

type Order = typeof orders.$inferSelect;
type OrderItem = typeof orderItems.$inferSelect;
type Address = typeof addresses.$inferSelect;

function formatRupees(paise: number): string {
  return `Rs ${(paise / 100).toFixed(2)}`;
}

// Server-rendered on first GET /orders/:id/invoice request, then cached in
// the `invoices` Storage bucket (Milestone 5 plan §Backend) -- simple enough
// layout that a library beyond pdf-lib isn't worth pulling in for Phase 5.
export async function generateInvoicePdf(input: {
  order: Order;
  items: OrderItem[];
  address: Address | null;
}): Promise<Uint8Array> {
  const { order, items, address } = input;

  const pdfDoc = await PDFDocument.create();
  const page = pdfDoc.addPage([595, 842]); // A4 in points
  const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
  const bold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

  let y = 800;
  const draw = (text: string, x: number, size = 11, useFont = font) => {
    page.drawText(text, { x, y, size, font: useFont, color: rgb(0, 0, 0) });
  };

  draw("Baker Ally", 50, 20, bold);
  y -= 28;
  draw("Tax Invoice", 50, 14, bold);
  y -= 24;
  draw(`Order ID: ${order.id}`, 50, 10);
  y -= 14;
  draw(`Date: ${order.createdAt.toISOString().slice(0, 10)}`, 50, 10);
  y -= 14;
  draw(`Status: ${order.status}`, 50, 10);
  y -= 28;

  if (address) {
    draw("Delivery Address", 50, 11, bold);
    y -= 15;
    if (address.label) {
      draw(address.label, 50, 10);
      y -= 13;
    }
    draw(address.line1, 50, 10);
    y -= 13;
    if (address.line2) {
      draw(address.line2, 50, 10);
      y -= 13;
    }
    draw(`${address.city}, ${address.state} ${address.pincode}`, 50, 10);
    y -= 26;
  }

  draw("Items", 50, 11, bold);
  y -= 16;
  draw("Product", 50, 9, bold);
  draw("Qty", 340, 9, bold);
  draw("Unit Price", 400, 9, bold);
  draw("Amount", 490, 9, bold);
  y -= 13;

  for (const item of items) {
    draw(`${item.productName} (${item.variantName})`.slice(0, 48), 50, 9);
    draw(String(item.quantity), 340, 9);
    draw(formatRupees(item.unitPrice), 400, 9);
    draw(formatRupees(item.unitPrice * item.quantity), 490, 9);
    y -= 15;
  }

  y -= 12;
  draw(`Subtotal: ${formatRupees(order.subtotal)}`, 400, 10);
  y -= 14;
  if (order.discountValue > 0) {
    draw(`Discount: -${formatRupees(order.discountValue)}`, 400, 10);
    y -= 14;
  }
  draw(`Shipping: ${formatRupees(order.shippingCost)}`, 400, 10);
  y -= 14;
  draw(`Total: ${formatRupees(order.total)}`, 400, 12, bold);

  return await pdfDoc.save();
}

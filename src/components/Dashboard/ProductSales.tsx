import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { startOfDay, endOfDay } from "date-fns";

interface ProductSalesProps {
  selectedDate: Date;
}

export function ProductSales({ selectedDate }: ProductSalesProps) {
  const { data: productSales, isLoading } = useQuery({
    queryKey: ["product-sales", selectedDate],
    queryFn: async () => {
      const start = startOfDay(selectedDate);
      const end = endOfDay(selectedDate);

      // Get all sales records for the selected date
      const { data: records, error } = await supabase
        .from("sales_records")
        .select("product_name, quantity, total_price")
        .gte("sale_date", start.toISOString())
        .lte("sale_date", end.toISOString());

      if (error) throw error;

      if (!records || records.length === 0) return [];

      // Aggregate by product
      const productMap = new Map<string, { quantity: number; revenue: number }>();

      records.forEach((record) => {
        const existing = productMap.get(record.product_name) || { quantity: 0, revenue: 0 };
        productMap.set(record.product_name, {
          quantity: existing.quantity + record.quantity,
          revenue: existing.revenue + Number(record.total_price),
        });
      });

      return Array.from(productMap.entries())
        .map(([name, data]) => ({ name, ...data }))
        .sort((a, b) => b.revenue - a.revenue);
    },
  });

  return (
    <Card>
      <CardHeader>
        <CardTitle>Product Sales</CardTitle>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="text-center text-muted-foreground">Loading...</div>
        ) : productSales && productSales.length > 0 ? (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Product</TableHead>
                <TableHead className="text-right">Quantity Sold</TableHead>
                <TableHead className="text-right">Revenue</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {productSales.map((product) => (
                <TableRow key={product.name}>
                  <TableCell className="font-medium">{product.name}</TableCell>
                  <TableCell className="text-right">{product.quantity}</TableCell>
                  <TableCell className="text-right">₹{product.revenue.toFixed(2)}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        ) : (
          <div className="text-center text-muted-foreground py-4">
            No sales data for selected date
          </div>
        )}
      </CardContent>
    </Card>
  );
}

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useDate } from "@/contexts/DateContext";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Button } from "@/components/ui/button";
import { TrendingUp, DollarSign, LineChart, CalendarIcon } from "lucide-react";
import { YearlyProfitChart } from "@/components/Profits/YearlyProfitChart";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Calendar } from "@/components/ui/calendar";
import { cn } from "@/lib/utils";
import { format, startOfDay, endOfDay, startOfMonth, endOfMonth, startOfYear, endOfYear } from "date-fns";

export default function Profits() {
  const [showGraph, setShowGraph] = useState(false);
  const { selectedDate } = useDate();
  const [localDate, setLocalDate] = useState<Date>(new Date());

  const getProfitData = async (startDate: Date, endDate: Date) => {
    const { data, error } = await supabase
      .from("sales_records")
      .select("product_id, product_name, quantity, total_price, unit_price, cost_per_unit, total_profit, sale_date")
      .gte("sale_date", startDate.toISOString())
      .lte("sale_date", endDate.toISOString());

    if (error) throw error;

    let totalRevenue = 0;
    let totalCost = 0;
    const productProfits: any = {};

    data.forEach((record: any) => {
      const itemCost = Number(record.cost_per_unit) * record.quantity;
      const itemRevenue = Number(record.total_price);
      const itemProfit = Number(record.total_profit);

      totalRevenue += itemRevenue;
      totalCost += itemCost;

      if (!productProfits[record.product_id]) {
        productProfits[record.product_id] = {
          product_id: record.product_id,
          product_name: record.product_name,
          total_quantity: 0,
          total_revenue: 0,
          total_cost: 0,
          total_profit: 0,
          avg_sale_price: 0,
          avg_cost_price: 0,
        };
      }

      productProfits[record.product_id].total_quantity += record.quantity;
      productProfits[record.product_id].total_revenue += itemRevenue;
      productProfits[record.product_id].total_cost += itemCost;
      productProfits[record.product_id].total_profit += itemProfit;
    });

    Object.values(productProfits).forEach((p: any) => {
      p.avg_sale_price = p.total_revenue / p.total_quantity;
      p.avg_cost_price = p.total_cost / p.total_quantity;
    });

    return {
      totalProfit: totalRevenue - totalCost,
      totalRevenue,
      totalCost,
      products: Object.values(productProfits).sort((a: any, b: any) => b.total_profit - a.total_profit),
    };
  };

  const { data: todayData } = useQuery({
    queryKey: ["profit-today", localDate],
    queryFn: () => getProfitData(startOfDay(localDate), endOfDay(localDate)),
  });

  const { data: monthData } = useQuery({
    queryKey: ["profit-month", localDate],
    queryFn: () => getProfitData(startOfMonth(localDate), endOfMonth(localDate)),
  });

  const { data: yearData } = useQuery({
    queryKey: ["profit-year", localDate],
    queryFn: () => getProfitData(startOfYear(localDate), endOfYear(localDate)),
  });

  const renderProfitCard = (title: string, amount: number, description: string) => (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium">{title}</CardTitle>
        <DollarSign className="h-4 w-4 text-muted-foreground" />
      </CardHeader>
      <CardContent>
        <div className={`text-2xl font-bold ${amount >= 0 ? 'text-green-600' : 'text-red-600'}`}>
          ₹{amount.toFixed(2)}
        </div>
        <p className="text-xs text-muted-foreground">{description}</p>
      </CardContent>
    </Card>
  );

  const renderTable = (products: any[] | undefined) => {
    if (!products || products.length === 0) {
      return <div className="text-center py-8 text-muted-foreground">No data available</div>;
    }

    return (
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Product Name</TableHead>
            <TableHead className="text-right">Units Sold</TableHead>
            <TableHead className="text-right">Cost Price</TableHead>
            <TableHead className="text-right">Sale Price</TableHead>
            <TableHead className="text-right">Profit</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {products.map((product: any) => (
            <TableRow key={product.product_id}>
              <TableCell className="font-medium">{product.product_name}</TableCell>
              <TableCell className="text-right">{product.total_quantity}</TableCell>
              <TableCell className="text-right">₹{product.avg_cost_price.toFixed(2)}</TableCell>
              <TableCell className="text-right">₹{product.avg_sale_price.toFixed(2)}</TableCell>
              <TableCell className={`text-right font-semibold ${product.total_profit >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                ₹{product.total_profit.toFixed(2)}
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    );
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Profits</h1>
          <p className="text-muted-foreground mt-1">Track your business profitability</p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" onClick={() => setShowGraph(true)}>
            <LineChart className="mr-2 h-4 w-4" />
            12-Month Graph
          </Button>
          <Popover>
            <PopoverTrigger asChild>
              <Button
                variant="outline"
                className={cn(
                  "w-[240px] justify-start text-left font-normal",
                  !localDate && "text-muted-foreground"
                )}
              >
                <CalendarIcon className="mr-2 h-4 w-4" />
                {localDate ? format(localDate, "PPP") : <span>Pick a date</span>}
              </Button>
            </PopoverTrigger>
            <PopoverContent className="w-auto p-0" align="end">
              <Calendar
                mode="single"
                selected={localDate}
                onSelect={(date) => date && setLocalDate(date)}
                initialFocus
                className={cn("p-3 pointer-events-auto")}
              />
            </PopoverContent>
          </Popover>
        </div>
      </div>

      <YearlyProfitChart open={showGraph} onOpenChange={setShowGraph} />

      <Tabs defaultValue="today" className="space-y-4">
        <TabsList>
          <TabsTrigger value="today">Today</TabsTrigger>
          <TabsTrigger value="month">This Month</TabsTrigger>
          <TabsTrigger value="year">This Year</TabsTrigger>
        </TabsList>

        <TabsContent value="today" className="space-y-4">
          {renderProfitCard("Today's Profit", todayData?.totalProfit || 0, format(localDate, "PPP"))}
          <Card>
            <CardHeader>
              <CardTitle>Product Profitability - Today</CardTitle>
            </CardHeader>
            <CardContent>
              {renderTable(todayData?.products)}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="month" className="space-y-4">
          {renderProfitCard("This Month's Profit", monthData?.totalProfit || 0, format(localDate, "MMMM yyyy"))}
          <Card>
            <CardHeader>
              <CardTitle>Product Profitability - This Month</CardTitle>
            </CardHeader>
            <CardContent>
              {renderTable(monthData?.products)}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="year" className="space-y-4">
          {renderProfitCard("This Year's Profit", yearData?.totalProfit || 0, format(localDate, "yyyy"))}
          <Card>
            <CardHeader>
              <CardTitle>Product Profitability - This Year</CardTitle>
            </CardHeader>
            <CardContent>
              {renderTable(yearData?.products)}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}

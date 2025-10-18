/*
  # Complete Inventory Management System Schema
  
  1. New Tables
    - `user_roles`: User role assignments (admin, staff, owner)
    - `categories`: Product categories
    - `sizes`: Available product sizes (XS, S, M, L, XL, XXL, XXXL)
    - `colors`: Color options for products with hex codes
    - `products`: Product inventory with pricing, stock, and details
    - `product_inventory`: Granular inventory tracking per product-size-color
    - `product_size_prices`: Different prices for different sizes
    - `invoices`: Sales invoices with customer and payment information
    - `invoice_items`: Line items for each invoice with size and color info
    - `sales_records`: Completed sales data for analytics (separate from invoices)
    - `store_settings`: Store configuration, branding, and social media settings
  
  2. Storage Buckets
    - `product-images`: Public bucket for product images
    - `store-assets`: Public bucket for store logos, QR codes, and assets
  
  3. Security
    - Enable RLS on all tables
    - Authenticated users can manage their store data
    - Public read access to storage buckets
    - Secure policies for all data access
  
  4. Key Features
    - Multi-size and multi-color product support
    - Invoice generation with tax, discount, and payment status tracking
    - Sales records separated from invoices for accurate reporting
    - Low stock threshold monitoring
    - Social media QR code integration (WhatsApp, Instagram)
    - Customizable store branding
    - Automatic invoice numbering
    - No limits on data creation
*/

-- Create enum for user roles
DO $$ BEGIN
  CREATE TYPE public.app_role AS ENUM ('admin', 'staff', 'owner');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Create user_roles table
CREATE TABLE IF NOT EXISTS public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role app_role NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(user_id, role)
);

-- Create categories table
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create sizes table
CREATE TABLE IF NOT EXISTS public.sizes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Insert default sizes
INSERT INTO public.sizes (name, sort_order) VALUES
  ('XS', 1),
  ('S', 2),
  ('M', 3),
  ('L', 4),
  ('XL', 5),
  ('XXL', 6),
  ('XXXL', 7)
ON CONFLICT (name) DO NOTHING;

-- Create colors table
CREATE TABLE IF NOT EXISTS public.colors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  hex_code TEXT,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Insert default colors
INSERT INTO public.colors (name, hex_code, sort_order) VALUES
  ('Black', '#000000', 1),
  ('White', '#FFFFFF', 2),
  ('Red', '#FF0000', 3),
  ('Blue', '#0000FF', 4),
  ('Green', '#008000', 5),
  ('Yellow', '#FFFF00', 6),
  ('Pink', '#FFC0CB', 7),
  ('Grey', '#808080', 8)
ON CONFLICT (name) DO NOTHING;

-- Create products table
CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
  size_ids UUID[] DEFAULT '{}',
  color_ids UUID[] DEFAULT '{}',
  price_inr DECIMAL(10, 2) NOT NULL,
  cost_inr DECIMAL(10, 2),
  quantity_in_stock INTEGER NOT NULL DEFAULT 0,
  image_url TEXT,
  secondary_image_url TEXT,
  description TEXT,
  sku TEXT UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create product_inventory table
CREATE TABLE IF NOT EXISTS public.product_inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
  size_id UUID REFERENCES public.sizes(id) ON DELETE CASCADE NOT NULL,
  color_id UUID REFERENCES public.colors(id) ON DELETE CASCADE NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(product_id, size_id, color_id)
);

-- Create product_size_prices table
CREATE TABLE IF NOT EXISTS public.product_size_prices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
  size_id UUID REFERENCES public.sizes(id) ON DELETE CASCADE NOT NULL,
  price_inr NUMERIC(10, 2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(product_id, size_id)
);

-- Create invoices table
CREATE TABLE IF NOT EXISTS public.invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number TEXT NOT NULL UNIQUE,
  customer_name TEXT,
  customer_phone TEXT,
  subtotal DECIMAL(10, 2) NOT NULL,
  tax_percentage DECIMAL(5, 2) DEFAULT 0,
  tax_amount DECIMAL(10, 2) DEFAULT 0,
  discount_amount DECIMAL(10, 2) DEFAULT 0,
  discount_type TEXT DEFAULT 'percentage',
  grand_total DECIMAL(10, 2) NOT NULL,
  payment_status TEXT DEFAULT 'done' CHECK (payment_status IN ('done', 'pending')),
  expected_payment_date DATE,
  pdf_url TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create invoice_items table
CREATE TABLE IF NOT EXISTS public.invoice_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID REFERENCES public.invoices(id) ON DELETE CASCADE NOT NULL,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  product_name TEXT NOT NULL,
  size_name TEXT,
  color_name TEXT,
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(10, 2) NOT NULL,
  total_price DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create sales_records table (for analytics and reporting)
CREATE TABLE IF NOT EXISTS public.sales_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID REFERENCES public.invoices(id) ON DELETE SET NULL,
  invoice_number TEXT NOT NULL,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  product_name TEXT NOT NULL,
  size_name TEXT,
  color_name TEXT,
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(10, 2) NOT NULL,
  total_price DECIMAL(10, 2) NOT NULL,
  cost_per_unit DECIMAL(10, 2),
  profit_per_unit DECIMAL(10, 2),
  total_profit DECIMAL(10, 2),
  sale_date TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create store_settings table
CREATE TABLE IF NOT EXISTS public.store_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_name TEXT NOT NULL DEFAULT 'My Garment Store',
  address TEXT,
  phone TEXT,
  email TEXT,
  tax_percentage DECIMAL(5, 2) DEFAULT 0,
  logo_url TEXT,
  currency_symbol TEXT DEFAULT '₹',
  invoice_font_family TEXT DEFAULT 'helvetica',
  invoice_primary_color TEXT DEFAULT '#000000',
  invoice_secondary_color TEXT DEFAULT '#666666',
  low_stock_threshold INTEGER DEFAULT 10,
  whatsapp_channel TEXT DEFAULT '',
  whatsapp_channel_name TEXT DEFAULT '',
  instagram_page TEXT DEFAULT '',
  instagram_page_id TEXT DEFAULT '',
  whatsapp_tagline TEXT DEFAULT 'Join our WhatsApp group',
  instagram_tagline TEXT DEFAULT 'Follow us on Instagram',
  whatsapp_qr_url TEXT DEFAULT '',
  instagram_qr_url TEXT DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Insert default store settings if not exists
INSERT INTO public.store_settings (store_name, tax_percentage, low_stock_threshold) 
VALUES ('My Garment Store', 18.00, 10)
ON CONFLICT DO NOTHING;

-- Enable Row Level Security on all tables
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sizes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.colors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_size_prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_roles
CREATE POLICY "Authenticated users can view user roles"
  ON public.user_roles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can manage user roles"
  ON public.user_roles FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS Policies for categories
CREATE POLICY "Authenticated users can view categories"
  ON public.categories FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can create categories"
  ON public.categories FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update categories"
  ON public.categories FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Authenticated users can delete categories"
  ON public.categories FOR DELETE
  TO authenticated
  USING (true);

-- RLS Policies for sizes
CREATE POLICY "Authenticated users can view sizes"
  ON public.sizes FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can create sizes"
  ON public.sizes FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update sizes"
  ON public.sizes FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Authenticated users can delete sizes"
  ON public.sizes FOR DELETE
  TO authenticated
  USING (true);

-- RLS Policies for colors
CREATE POLICY "Authenticated users can view colors"
  ON public.colors FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can create colors"
  ON public.colors FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update colors"
  ON public.colors FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Authenticated users can delete colors"
  ON public.colors FOR DELETE
  TO authenticated
  USING (true);

-- RLS Policies for products
CREATE POLICY "Authenticated users can view products"
  ON public.products FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can create products"
  ON public.products FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update products"
  ON public.products FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Authenticated users can delete products"
  ON public.products FOR DELETE
  TO authenticated
  USING (true);

-- RLS Policies for product_inventory
CREATE POLICY "Authenticated users can view product inventory"
  ON public.product_inventory FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can create product inventory"
  ON public.product_inventory FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update product inventory"
  ON public.product_inventory FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Authenticated users can delete product inventory"
  ON public.product_inventory FOR DELETE
  TO authenticated
  USING (true);

-- RLS Policies for product_size_prices
CREATE POLICY "Authenticated users can view product size prices"
  ON public.product_size_prices FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can create product size prices"
  ON public.product_size_prices FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update product size prices"
  ON public.product_size_prices FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Authenticated users can delete product size prices"
  ON public.product_size_prices FOR DELETE
  TO authenticated
  USING (true);

-- RLS Policies for invoices
CREATE POLICY "Authenticated users can view invoices"
  ON public.invoices FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can create invoices"
  ON public.invoices FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update invoices"
  ON public.invoices FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Authenticated users can delete invoices"
  ON public.invoices FOR DELETE
  TO authenticated
  USING (true);

-- RLS Policies for invoice_items
CREATE POLICY "Authenticated users can view invoice items"
  ON public.invoice_items FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can create invoice items"
  ON public.invoice_items FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update invoice items"
  ON public.invoice_items FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Authenticated users can delete invoice items"
  ON public.invoice_items FOR DELETE
  TO authenticated
  USING (true);

-- RLS Policies for sales_records
CREATE POLICY "Authenticated users can view sales records"
  ON public.sales_records FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can create sales records"
  ON public.sales_records FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update sales records"
  ON public.sales_records FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Authenticated users can delete sales records"
  ON public.sales_records FOR DELETE
  TO authenticated
  USING (true);

-- RLS Policies for store_settings
CREATE POLICY "Authenticated users can view store settings"
  ON public.store_settings FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can update store settings"
  ON public.store_settings FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Authenticated users can create store settings"
  ON public.store_settings FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('product-images', 'product-images', true),
  ('store-assets', 'store-assets', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for product-images
CREATE POLICY "Authenticated users can upload product images"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'product-images');

CREATE POLICY "Anyone can view product images"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'product-images');

CREATE POLICY "Authenticated users can update product images"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'product-images')
  WITH CHECK (bucket_id = 'product-images');

CREATE POLICY "Authenticated users can delete product images"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'product-images');

-- Storage policies for store-assets
CREATE POLICY "Authenticated users can upload store assets"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'store-assets');

CREATE POLICY "Anyone can view store assets"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'store-assets');

CREATE POLICY "Authenticated users can update store assets"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'store-assets')
  WITH CHECK (bucket_id = 'store-assets');

CREATE POLICY "Authenticated users can delete store assets"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'store-assets');

-- Function to auto-generate invoice numbers
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TRIGGER AS $$
DECLARE
  next_number INTEGER;
  new_invoice_number TEXT;
BEGIN
  IF NEW.invoice_number IS NULL OR NEW.invoice_number = '' THEN
    SELECT COALESCE(
      MAX(
        CAST(
          SUBSTRING(invoice_number FROM 'INV-([0-9]+)') AS INTEGER
        )
      ), 
      0
    ) + 1 INTO next_number
    FROM invoices
    WHERE invoice_number ~ 'INV-[0-9]+';
    
    new_invoice_number := 'INV-' || LPAD(next_number::TEXT, 6, '0');
    NEW.invoice_number := new_invoice_number;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for auto-generating invoice numbers
DROP TRIGGER IF EXISTS set_invoice_number ON invoices;
CREATE TRIGGER set_invoice_number
  BEFORE INSERT ON invoices
  FOR EACH ROW
  EXECUTE FUNCTION generate_invoice_number();

-- Function to automatically create sales records when invoice status is "done"
CREATE OR REPLACE FUNCTION create_sales_records_on_invoice()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create sales records for "done" invoices
  IF NEW.payment_status = 'done' THEN
    INSERT INTO public.sales_records (
      invoice_id,
      invoice_number,
      product_id,
      product_name,
      size_name,
      color_name,
      quantity,
      unit_price,
      total_price,
      cost_per_unit,
      profit_per_unit,
      total_profit,
      sale_date
    )
    SELECT 
      NEW.id,
      NEW.invoice_number,
      ii.product_id,
      ii.product_name,
      ii.size_name,
      ii.color_name,
      ii.quantity,
      ii.unit_price,
      ii.total_price,
      COALESCE(p.cost_inr, 0),
      COALESCE(ii.unit_price - p.cost_inr, ii.unit_price),
      COALESCE((ii.unit_price - p.cost_inr) * ii.quantity, ii.total_price),
      NEW.created_at
    FROM public.invoice_items ii
    LEFT JOIN public.products p ON ii.product_id = p.id
    WHERE ii.invoice_id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create sales records when invoice is inserted as "done"
DROP TRIGGER IF EXISTS create_sales_on_invoice_insert ON invoices;
CREATE TRIGGER create_sales_on_invoice_insert
  AFTER INSERT ON invoices
  FOR EACH ROW
  EXECUTE FUNCTION create_sales_records_on_invoice();

-- Function to manage sales records when invoice status changes
CREATE OR REPLACE FUNCTION manage_sales_records_on_invoice_update()
RETURNS TRIGGER AS $$
BEGIN
  -- If status changed from "pending" to "done", create sales records
  IF OLD.payment_status = 'pending' AND NEW.payment_status = 'done' THEN
    INSERT INTO public.sales_records (
      invoice_id,
      invoice_number,
      product_id,
      product_name,
      size_name,
      color_name,
      quantity,
      unit_price,
      total_price,
      cost_per_unit,
      profit_per_unit,
      total_profit,
      sale_date
    )
    SELECT 
      NEW.id,
      NEW.invoice_number,
      ii.product_id,
      ii.product_name,
      ii.size_name,
      ii.color_name,
      ii.quantity,
      ii.unit_price,
      ii.total_price,
      COALESCE(p.cost_inr, 0),
      COALESCE(ii.unit_price - p.cost_inr, ii.unit_price),
      COALESCE((ii.unit_price - p.cost_inr) * ii.quantity, ii.total_price),
      NEW.created_at
    FROM public.invoice_items ii
    LEFT JOIN public.products p ON ii.product_id = p.id
    WHERE ii.invoice_id = NEW.id;
  END IF;
  
  -- If status changed from "done" to "pending", delete sales records
  IF OLD.payment_status = 'done' AND NEW.payment_status = 'pending' THEN
    DELETE FROM public.sales_records WHERE invoice_id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to manage sales records on invoice update
DROP TRIGGER IF EXISTS manage_sales_on_invoice_update ON invoices;
CREATE TRIGGER manage_sales_on_invoice_update
  AFTER UPDATE ON invoices
  FOR EACH ROW
  WHEN (OLD.payment_status IS DISTINCT FROM NEW.payment_status)
  EXECUTE FUNCTION manage_sales_records_on_invoice_update();

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_sales_records_sale_date ON public.sales_records(sale_date);
CREATE INDEX IF NOT EXISTS idx_sales_records_invoice_id ON public.sales_records(invoice_id);
CREATE INDEX IF NOT EXISTS idx_sales_records_product_id ON public.sales_records(product_id);
CREATE INDEX IF NOT EXISTS idx_invoices_payment_status ON public.invoices(payment_status);
CREATE INDEX IF NOT EXISTS idx_invoices_created_at ON public.invoices(created_at);
CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice_id ON public.invoice_items(invoice_id);
CREATE INDEX IF NOT EXISTS idx_products_category_id ON public.products(category_id);
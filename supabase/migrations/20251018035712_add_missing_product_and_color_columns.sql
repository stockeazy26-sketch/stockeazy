/*
  # Add Missing Columns to Products and Colors Tables
  
  1. Changes
    - Add sort_order to colors table for custom ordering
    - Add color_ids array to products table to store multiple colors per product
    - Add secondary_image_url to products table for additional product images
  
  2. Security
    - No RLS changes needed
*/

DO $$
BEGIN
  -- Add sort_order to colors table
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'colors' AND column_name = 'sort_order'
  ) THEN
    ALTER TABLE colors ADD COLUMN sort_order INTEGER DEFAULT 0;
  END IF;

  -- Add color_ids to products table
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'products' AND column_name = 'color_ids'
  ) THEN
    ALTER TABLE products ADD COLUMN color_ids UUID[] DEFAULT '{}';
  END IF;

  -- Add secondary_image_url to products table
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'products' AND column_name = 'secondary_image_url'
  ) THEN
    ALTER TABLE products ADD COLUMN secondary_image_url TEXT;
  END IF;
END $$;
/*
  # Add QR Code Storage Fields to Store Settings
  
  1. Changes
    - Add whatsapp_qr_url field to store uploaded WhatsApp QR code
    - Add instagram_qr_url field to store uploaded Instagram QR code
    - These will replace the need to generate QR codes from URLs
  
  2. Details
    - QR codes will be uploaded to storage and URLs stored in these fields
    - This allows users to upload custom QR codes
    - The uploaded QR codes will be displayed on invoices
  
  3. Security
    - No RLS changes needed
*/

DO $$
BEGIN
  -- Add QR code URL storage fields
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'store_settings' AND column_name = 'whatsapp_qr_url'
  ) THEN
    ALTER TABLE store_settings ADD COLUMN whatsapp_qr_url TEXT DEFAULT '';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'store_settings' AND column_name = 'instagram_qr_url'
  ) THEN
    ALTER TABLE store_settings ADD COLUMN instagram_qr_url TEXT DEFAULT '';
  END IF;
  
  -- Ensure whatsapp_channel_name exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'store_settings' AND column_name = 'whatsapp_channel_name'
  ) THEN
    ALTER TABLE store_settings ADD COLUMN whatsapp_channel_name TEXT DEFAULT '';
  END IF;

  -- Ensure instagram_page_id exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'store_settings' AND column_name = 'instagram_page_id'
  ) THEN
    ALTER TABLE store_settings ADD COLUMN instagram_page_id TEXT DEFAULT '';
  END IF;
END $$;
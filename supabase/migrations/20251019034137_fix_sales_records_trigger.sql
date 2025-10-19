/*
  # Fix Sales Records Trigger Issue
  
  1. Changes
    - Drop the AFTER INSERT trigger that tries to create sales records immediately
    - Keep the UPDATE trigger for status changes
    - Sales records will be created manually from the application after items are inserted
  
  2. Reason
    - The AFTER INSERT trigger runs before invoice_items are inserted
    - This causes sales_records to not be created for invoices with payment_status = 'done'
    - Moving this logic to the application ensures items exist before creating sales records
*/

-- Drop the problematic trigger
DROP TRIGGER IF EXISTS create_sales_on_invoice_insert ON invoices;

-- Keep the function for potential manual use but don't trigger it automatically
-- The UPDATE trigger remains for status changes which works correctly
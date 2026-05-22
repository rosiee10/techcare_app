-- Fix pharmacy_purchase_request_items table - add missing purchase_request_id column

-- First, check if the column exists
-- Add the purchase_request_id column if it doesn't exist
ALTER TABLE pch.pharmacy_purchase_request_items 
ADD COLUMN IF NOT EXISTS purchase_request_id INTEGER REFERENCES pch.pharmacy_purchase_requests(pr_id);

-- Also ensure other required columns exist
ALTER TABLE pch.pharmacy_purchase_request_items 
ADD COLUMN IF NOT EXISTS requested_by_module VARCHAR(20);

ALTER TABLE pch.pharmacy_purchase_request_items 
ADD COLUMN IF NOT EXISTS item_type VARCHAR(10);

ALTER TABLE pch.pharmacy_purchase_request_items 
ADD COLUMN IF NOT EXISTS qty_requested NUMERIC(12,2);

-- Update existing records if needed (set defaults for any null required fields)
UPDATE pch.pharmacy_purchase_request_items 
SET requested_by_module = 'PHARMACY' 
WHERE requested_by_module IS NULL;

UPDATE pch.pharmacy_purchase_request_items 
SET item_type = 'MEDICINE' 
WHERE item_type IS NULL;

UPDATE pch.pharmacy_purchase_request_items 
SET qty_requested = 0 
WHERE qty_requested IS NULL;

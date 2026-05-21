-- Fix: The column should be pr_id not purchase_request_id
-- First drop the wrong column if it exists
ALTER TABLE pch.pharmacy_purchase_request_items 
DROP COLUMN IF EXISTS purchase_request_id;

-- Add the correct column pr_id
ALTER TABLE pch.pharmacy_purchase_request_items 
ADD COLUMN IF NOT EXISTS pr_id INTEGER REFERENCES pch.pharmacy_purchase_requests(pr_id);

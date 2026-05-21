-- Add medicine_name column to store name when medicine not in inventory
ALTER TABLE pch.pharmacy_purchase_request_items 
ADD COLUMN IF NOT EXISTS medicine_name VARCHAR(255);

-- Add comment
COMMENT ON COLUMN pch.pharmacy_purchase_request_items.medicine_name IS 'Medicine name for items not yet in inventory (when medicine_id is null)';

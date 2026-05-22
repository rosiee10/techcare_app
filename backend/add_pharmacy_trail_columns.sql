-- Add trail and updated_trail columns to pharmacy module tables
-- Format: complete name | username | role | sub role (skip if null) | deployment (skip if null) | date and time | ip address
-- Data type: character varying(120)

-- Tables that need trail column added
ALTER TABLE pch.pharmacy_suppliers ADD COLUMN IF NOT EXISTS trail character varying(120);
ALTER TABLE pch.pharmacy_locations ADD COLUMN IF NOT EXISTS trail character varying(120);
ALTER TABLE pch.pharmacy_medicines ADD COLUMN IF NOT EXISTS trail character varying(120);
ALTER TABLE pch.pharmacy_stock_batches ADD COLUMN IF NOT EXISTS trail character varying(120);
ALTER TABLE pch.pharmacy_inventory_balance ADD COLUMN IF NOT EXISTS trail character varying(120);
ALTER TABLE pch.pharmacy_purchase_request_items ADD COLUMN IF NOT EXISTS trail character varying(120);
ALTER TABLE pch.pharmacy_goods_receipts ADD COLUMN IF NOT EXISTS trail character varying(120);
ALTER TABLE pch.pharmacy_goods_receipt_items ADD COLUMN IF NOT EXISTS trail character varying(120);
ALTER TABLE pch.pharmacy_charge_slip_items ADD COLUMN IF NOT EXISTS trail character varying(120);
ALTER TABLE pch.pharmacy_dispense_receipt_items ADD COLUMN IF NOT EXISTS trail character varying(120);
ALTER TABLE pch.pharmacy_inventory_adjustment_items ADD COLUMN IF NOT EXISTS trail character varying(120);

-- Tables that need updated_trail column added
ALTER TABLE pch.pharmacy_transactions ADD COLUMN IF NOT EXISTS updated_trail character varying(120);
ALTER TABLE pch.pharmacy_charge_slips ADD COLUMN IF NOT EXISTS updated_trail character varying(120);
ALTER TABLE pch.pharmacy_dispense_receipts ADD COLUMN IF NOT EXISTS updated_trail character varying(120);
ALTER TABLE pch.pharmacy_inventory_adjustments ADD COLUMN IF NOT EXISTS updated_trail character varying(120);

-- Note: pharmacy_purchase_requests already has both trail and updated_trail columns

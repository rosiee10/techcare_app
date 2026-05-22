-- =============================================================================
-- PHARMACY DATABASE MIGRATION SCRIPT
-- From: techcare_db ni burgos.sql (old schema)
-- To: techcare_db.sql (new schema with full pharmacy features)
-- =============================================================================

-- 1. ADD unit_cost COLUMN TO pharmacy_medicines
ALTER TABLE pch.pharmacy_medicines 
ADD COLUMN IF NOT EXISTS unit_cost numeric(12,2) DEFAULT 0;

COMMENT ON COLUMN pch.pharmacy_medicines.unit_cost IS 'Default/average cost per unit for the medicine';

-- 2. ADD unit_cost COLUMN TO pharmacy_stock_batches (THIS FIXES YOUR ERROR)
ALTER TABLE pch.pharmacy_stock_batches 
ADD COLUMN IF NOT EXISTS unit_cost numeric(12,2) DEFAULT 0;

COMMENT ON COLUMN pch.pharmacy_stock_batches.unit_cost IS 'Cost per unit for this specific batch (for FEFO costing)';

-- 3. ADD medicine_name COLUMN TO pharmacy_purchase_request_items
ALTER TABLE pch.pharmacy_purchase_request_items 
ADD COLUMN IF NOT EXISTS medicine_name character varying(255);

COMMENT ON COLUMN pch.pharmacy_purchase_request_items.medicine_name IS 'Medicine name for items not yet in inventory (when medicine_id is null)';

-- 4. DROP RESTRICTIVE CONSTRAINT (allows medicine_id to be NULL for new medicines)
ALTER TABLE pch.pharmacy_purchase_request_items 
DROP CONSTRAINT IF EXISTS chk_pr_item_type_match;

-- 5. ADD CHECK CONSTRAINTS FOR unit_cost (Idempotent)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'chk_pharmacy_medicines_unit_cost' 
        AND conrelid = 'pch.pharmacy_medicines'::regclass
    ) THEN
        ALTER TABLE pch.pharmacy_medicines 
        ADD CONSTRAINT chk_pharmacy_medicines_unit_cost 
        CHECK (unit_cost >= 0);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'chk_pharmacy_stock_batches_unit_cost' 
        AND conrelid = 'pch.pharmacy_stock_batches'::regclass
    ) THEN
        ALTER TABLE pch.pharmacy_stock_batches 
        ADD CONSTRAINT chk_pharmacy_stock_batches_unit_cost 
        CHECK (unit_cost >= 0);
    END IF;
END $$;

-- 6. SET DEFAULT VALUES FOR EXISTING RECORDS
UPDATE pch.pharmacy_medicines 
SET unit_cost = 0 
WHERE unit_cost IS NULL;

UPDATE pch.pharmacy_stock_batches 
SET unit_cost = 0 
WHERE unit_cost IS NULL;

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================
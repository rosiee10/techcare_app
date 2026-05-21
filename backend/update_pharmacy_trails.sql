-- Update existing null trail and updated_trail values in pharmacy tables
-- This script populates null values with a default audit trail format
-- Format: System | System | SYSTEM | | | 2026-05-13 00:00:00 | 127.0.0.1

-- Update trail columns
UPDATE pch.pharmacy_suppliers SET trail = 'System | System | SYSTEM | | | 2026-05-13 00:00:00 | 127.0.0.1' WHERE trail IS NULL;
UPDATE pch.pharmacy_locations SET trail = 'System | System | SYSTEM | | | 2026-05-13 00:00:00 | 127.0.0.1' WHERE trail IS NULL;
UPDATE pch.pharmacy_medicines SET trail = 'System | System | SYSTEM | | | 2026-05-13 00:00:00 | 127.0.0.1' WHERE trail IS NULL;
UPDATE pch.pharmacy_stock_batches SET trail = 'System | System | SYSTEM | | | 2026-05-13 00:00:00 | 127.0.0.1' WHERE trail IS NULL;
UPDATE pch.pharmacy_inventory_balance SET trail = 'System | System | SYSTEM | | | 2026-05-13 00:00:00 | 127.0.0.1' WHERE trail IS NULL;
UPDATE pch.pharmacy_transactions SET trail = 'System | System | SYSTEM | | | 2026-05-13 00:00:00 | 127.0.0.1' WHERE trail IS NULL;
UPDATE pch.pharmacy_purchase_requests SET trail = 'System | System | SYSTEM | | | 2026-05-13 00:00:00 | 127.0.0.1' WHERE trail IS NULL;
UPDATE pch.pharmacy_purchase_request_items SET trail = 'System | System | SYSTEM | | | 2026-05-13 00:00:00 | 127.0.0.1' WHERE trail IS NULL;
UPDATE pch.pharmacy_goods_receipts SET trail = 'System | System | SYSTEM | | | 2026-05-13 00:00:00 | 127.0.0.1' WHERE trail IS NULL;
UPDATE pch.pharmacy_goods_receipt_items SET trail = 'System | System | SYSTEM | | | 2026-05-13 00:00:00 | 127.0.0.1' WHERE trail IS NULL;
UPDATE pch.pharmacy_charge_slips SET trail = 'System | System | SYSTEM | | | 2026-05-13 00:00:00 | 127.0.0.1' WHERE trail IS NULL;
UPDATE pch.pharmacy_charge_slip_items SET trail = 'System | System | SYSTEM | | | 2026-05-13 00:00:00 | 127.0.0.1' WHERE trail IS NULL;
UPDATE pch.pharmacy_dispense_receipts SET trail = 'System | System | SYSTEM | | | 2026-05-13 00:00:00 | 127.0.0.1' WHERE trail IS NULL;
UPDATE pch.pharmacy_dispense_receipt_items SET trail = 'System | System | SYSTEM | | | 2026-05-13 00:00:00 | 127.0.0.1' WHERE trail IS NULL;
UPDATE pch.pharmacy_inventory_adjustments SET trail = 'System | System | SYSTEM | | | 2026-05-13 00:00:00 | 127.0.0.1' WHERE trail IS NULL;
UPDATE pch.pharmacy_inventory_adjustment_items SET trail = 'System | System | SYSTEM | | | 2026-05-13 00:00:00 | 127.0.0.1' WHERE trail IS NULL;

-- Update updated_trail columns
UPDATE pch.pharmacy_transactions SET updated_trail = 'System | System | SYSTEM | | | 2026-05-13 00:00:00 | 127.0.0.1' WHERE updated_trail IS NULL;
UPDATE pch.pharmacy_purchase_requests SET updated_trail = 'System | System | SYSTEM | | | 2026-05-13 00:00:00 | 127.0.0.1' WHERE updated_trail IS NULL;
UPDATE pch.pharmacy_charge_slips SET updated_trail = 'System | System | SYSTEM | | | 2026-05-13 00:00:00 | 127.0.0.1' WHERE updated_trail IS NULL;
UPDATE pch.pharmacy_dispense_receipts SET updated_trail = 'System | System | SYSTEM | | | 2026-05-13 00:00:00 | 127.0.0.1' WHERE updated_trail IS NULL;
UPDATE pch.pharmacy_inventory_adjustments SET updated_trail = 'System | System | SYSTEM | | | 2026-05-13 00:00:00 | 127.0.0.1' WHERE updated_trail IS NULL;

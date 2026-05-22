-- Fix: Drop the check constraint that prevents null medicine_id
-- This allows purchase requests for medicines not yet in inventory

ALTER TABLE pch.pharmacy_purchase_request_items 
DROP CONSTRAINT IF EXISTS chk_pr_item_type_match;

-- Add a new, less restrictive constraint if needed
-- Or leave it without constraint to allow flexibility

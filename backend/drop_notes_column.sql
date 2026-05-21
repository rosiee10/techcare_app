-- Drop the notes column from opd_room_location table
-- This column is no longer needed as we use trail and updated_trail for audit logging

ALTER TABLE opd_room_location DROP COLUMN IF EXISTS notes;

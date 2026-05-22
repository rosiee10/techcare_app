-- SQL to add per-day schedule columns to opd_service_schedule table
-- Run this directly in PostgreSQL

ALTER TABLE opd_service_schedule
    ADD COLUMN IF NOT EXISTS mon_open TIME,
    ADD COLUMN IF NOT EXISTS mon_close TIME,
    ADD COLUMN IF NOT EXISTS tue_open TIME,
    ADD COLUMN IF NOT EXISTS tue_close TIME,
    ADD COLUMN IF NOT EXISTS wed_open TIME,
    ADD COLUMN IF NOT EXISTS wed_close TIME,
    ADD COLUMN IF NOT EXISTS thu_open TIME,
    ADD COLUMN IF NOT EXISTS thu_close TIME,
    ADD COLUMN IF NOT EXISTS fri_open TIME,
    ADD COLUMN IF NOT EXISTS fri_close TIME,
    ADD COLUMN IF NOT EXISTS sat_open TIME,
    ADD COLUMN IF NOT EXISTS sat_close TIME;

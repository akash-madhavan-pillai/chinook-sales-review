-- ============================================================
-- scratchpad.sql
-- Schema discovery queries for the Chinook database.
-- Run once while exploring the database. NOT part of validation.
-- Results informed how 00_validation.sql was written.
-- ============================================================


-- 1. Primary keys
-- Shows the PK column(s) of every table.
-- Used for: Layer 2 (which columns to check for uniqueness).
-- Note: playlisttrack appears twice = composite key.
SELECT 
    tc.table_name,
    kcu.column_name AS primary_key_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.constraint_type = 'PRIMARY KEY'
    AND tc.table_schema = 'public'
ORDER BY tc.table_name;


-- 2. Foreign keys with nullability
-- Shows every FK link (child -> parent) and whether the FK can be blank.
-- Used for: Layer 3 (11 orphan checks; 4 nullable FKs need IS NOT NULL guards).
SELECT
    tc.table_name AS child_table,
    kcu.column_name AS fk_column,
    ccu.table_name AS parent_table,
    ccu.column_name AS parent_column,
    col.is_nullable AS fk_is_nullable
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
JOIN information_schema.columns col
    ON col.table_name = tc.table_name
    AND col.column_name = kcu.column_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;


-- 3. Full nullability map
-- Shows every column and whether it can be blank (YES/NO).
-- Used for: Layer 4 (only nullable columns used by Q1-Q3 need a blank audit).
SELECT table_name, column_name, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, is_nullable, ordinal_position;
-- Fix existing patient users with empty string email
-- Change empty string to NULL to avoid unique constraint issues

UPDATE pch.users
SET email = NULL
WHERE user_role = 'patient' 
  AND (email = '' OR email IS NULL);

-- Verify the fix
SELECT user_id, username, email, user_role
FROM pch.users
WHERE user_role = 'patient';

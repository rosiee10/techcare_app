-- Set must_change_pw = TRUE for all existing patient users
-- This forces them to change their password on next login

UPDATE pch.users
SET must_change_pw = TRUE,
    updated_trail = 'Force password change on next login'
WHERE user_role = 'patient'
  AND must_change_pw = FALSE;

-- Verify the update
SELECT user_id, username, user_role, must_change_pw
FROM pch.users
WHERE user_role = 'patient';

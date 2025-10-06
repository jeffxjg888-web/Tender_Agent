/*
  # Create default admin account setup function

  1. Function
    - Creates a PostgreSQL function to initialize default admin account
    - Only creates the account if it doesn't already exist
    - This function will be called from the application on first run
  
  2. Notes
    - The actual auth user must be created via Supabase Auth API
    - This migration prepares the database side
    - Password: admin123456
    - Email: admin@example.com
*/

-- Create a function to check if admin exists
CREATE OR REPLACE FUNCTION check_admin_exists()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users WHERE email = 'admin@example.com'
  );
END;
$$;

-- Create a function to insert admin user record (after auth user is created)
CREATE OR REPLACE FUNCTION create_admin_user_record(user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO users (id, email, full_name, role, created_at, updated_at)
  VALUES (
    user_id,
    'admin@example.com',
    'Admin',
    'admin',
    now(),
    now()
  )
  ON CONFLICT (id) DO NOTHING;
END;
$$;

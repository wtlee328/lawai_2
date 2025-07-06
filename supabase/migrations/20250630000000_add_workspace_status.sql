-- Add status column to workspaces table for soft delete functionality
ALTER TABLE "public"."workspaces" 
ADD COLUMN "status" text DEFAULT 'active' NOT NULL;

-- Add check constraint to ensure status is either 'active' or 'deleted'
ALTER TABLE "public"."workspaces" 
ADD CONSTRAINT "workspaces_status_check" 
CHECK ("status" IN ('active', 'deleted'));

-- Update RLS policy to only show active workspaces by default
DROP POLICY IF EXISTS "Users can manage their own workspaces" ON "public"."workspaces";

CREATE POLICY "Users can manage their own workspaces" ON "public"."workspaces"
    FOR ALL USING (("auth"."uid"() = "user_id") AND ("status" = 'active'));

-- Create separate policy for viewing deleted workspaces (if needed for admin purposes)
CREATE POLICY "Users can view their own deleted workspaces" ON "public"."workspaces"
    FOR SELECT USING (("auth"."uid"() = "user_id") AND ("status" = 'deleted'));
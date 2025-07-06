-- Rename workspaces table to tasks and update all references
-- This migration renames the workspaces table to tasks and updates all workspace_id columns to task_id

-- Step 1: Disable RLS temporarily to avoid conflicts during migration
ALTER TABLE "public"."chat_history" DISABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."documents" DISABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."search_results" DISABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."workspaces" DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop all existing RLS policies
DROP POLICY IF EXISTS "Users can manage their own chat_history." ON "public"."chat_history";
DROP POLICY IF EXISTS "Users can manage their own documents." ON "public"."documents";
DROP POLICY IF EXISTS "Users can manage their own search_results." ON "public"."search_results";
DROP POLICY IF EXISTS "Users can manage their own workspaces" ON "public"."workspaces";
DROP POLICY IF EXISTS "Users can view their own deleted workspaces" ON "public"."workspaces";

-- Step 3: Drop foreign key constraints that reference workspaces table
ALTER TABLE "public"."chat_history" DROP CONSTRAINT IF EXISTS "chat_history_workspace_id_fkey";
ALTER TABLE "public"."documents" DROP CONSTRAINT IF EXISTS "documents_workspace_id_fkey";
ALTER TABLE "public"."search_results" DROP CONSTRAINT IF EXISTS "search_results_workspace_id_fkey";

-- Step 4: Rename workspace_id columns to task_id in all tables
ALTER TABLE "public"."chat_history" RENAME COLUMN "workspace_id" TO "task_id";
ALTER TABLE "public"."documents" RENAME COLUMN "workspace_id" TO "task_id";
ALTER TABLE "public"."search_results" RENAME COLUMN "workspace_id" TO "task_id";

-- Step 5: Rename workspaces table to tasks
ALTER TABLE "public"."workspaces" RENAME TO "tasks";

-- Step 6: Rename constraints and indexes for the tasks table
ALTER TABLE "public"."tasks" RENAME CONSTRAINT "workspaces_pkey" TO "tasks_pkey";
ALTER TABLE "public"."tasks" RENAME CONSTRAINT "workspaces_user_id_fkey" TO "tasks_user_id_fkey";
ALTER TABLE "public"."tasks" RENAME CONSTRAINT "workspaces_status_check" TO "tasks_status_check";

-- Step 7: Re-create foreign key constraints with new names
ALTER TABLE "public"."chat_history"
    ADD CONSTRAINT "chat_history_task_id_fkey" 
    FOREIGN KEY ("task_id") REFERENCES "public"."tasks"("id") ON DELETE CASCADE;

ALTER TABLE "public"."documents"
    ADD CONSTRAINT "documents_task_id_fkey" 
    FOREIGN KEY ("task_id") REFERENCES "public"."tasks"("id") ON DELETE CASCADE;

ALTER TABLE "public"."search_results"
    ADD CONSTRAINT "search_results_task_id_fkey" 
    FOREIGN KEY ("task_id") REFERENCES "public"."tasks"("id") ON DELETE CASCADE;

-- Step 8: Re-enable RLS for all tables
ALTER TABLE "public"."chat_history" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."documents" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."search_results" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."tasks" ENABLE ROW LEVEL SECURITY;

-- Step 9: Create new RLS policies with updated table and column names
CREATE POLICY "Users can manage their own chat_history." ON "public"."chat_history" 
    USING ((select "auth"."uid"()) = "user_id") 
    WITH CHECK ((select "auth"."uid"()) = "user_id");

CREATE POLICY "Users can manage their own documents." ON "public"."documents" 
    USING ((select "auth"."uid"()) = "user_id") 
    WITH CHECK ((select "auth"."uid"()) = "user_id");

CREATE POLICY "Users can manage their own search_results." ON "public"."search_results" 
    USING ((select "auth"."uid"()) = "user_id") 
    WITH CHECK ((select "auth"."uid"()) = "user_id");

CREATE POLICY "Users can manage their own tasks" ON "public"."tasks"
    FOR ALL USING (((select "auth"."uid"()) = "user_id") AND ("status" = 'active'));

CREATE POLICY "Users can view their own deleted tasks" ON "public"."tasks"
    FOR SELECT USING (((select "auth"."uid"()) = "user_id") AND ("status" = 'deleted'));

-- Step 10: Update any comments or descriptions
COMMENT ON TABLE "public"."tasks" IS 'User tasks (formerly workspaces)';
COMMENT ON COLUMN "public"."chat_history"."task_id" IS 'Reference to the task (formerly workspace_id)';
COMMENT ON COLUMN "public"."documents"."task_id" IS 'Reference to the task (formerly workspace_id)';
COMMENT ON COLUMN "public"."search_results"."task_id" IS 'Reference to the task (formerly workspace_id)';
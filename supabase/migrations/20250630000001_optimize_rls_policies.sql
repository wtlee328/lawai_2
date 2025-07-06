-- Optimize RLS policies for all tables to improve performance
-- Replace auth.uid() with (select auth.uid()) to avoid re-evaluation for each row

-- Drop existing policies for all tables
DROP POLICY IF EXISTS "Users can manage their own chat_history." ON "public"."chat_history";
DROP POLICY IF EXISTS "Users can manage their own documents." ON "public"."documents";
DROP POLICY IF EXISTS "Users can manage their own search_results." ON "public"."search_results";
DROP POLICY IF EXISTS "Users can manage their own workspaces" ON "public"."workspaces";
DROP POLICY IF EXISTS "Users can view their own deleted workspaces" ON "public"."workspaces";

-- Create optimized policies for chat_history
CREATE POLICY "Users can manage their own chat_history." ON "public"."chat_history" 
    USING ((select "auth"."uid"()) = "user_id") 
    WITH CHECK ((select "auth"."uid"()) = "user_id");

-- Create optimized policies for documents
CREATE POLICY "Users can manage their own documents." ON "public"."documents" 
    USING ((select "auth"."uid"()) = "user_id") 
    WITH CHECK ((select "auth"."uid"()) = "user_id");

-- Create optimized policies for search_results
CREATE POLICY "Users can manage their own search_results." ON "public"."search_results" 
    USING ((select "auth"."uid"()) = "user_id") 
    WITH CHECK ((select "auth"."uid"()) = "user_id");

-- Create optimized policy for managing active workspaces
CREATE POLICY "Users can manage their own workspaces" ON "public"."workspaces"
    FOR ALL USING (((select "auth"."uid"()) = "user_id") AND ("status" = 'active'));

-- Create optimized policy for viewing deleted workspaces
CREATE POLICY "Users can view their own deleted workspaces" ON "public"."workspaces"
    FOR SELECT USING (((select "auth"."uid"()) = "user_id") AND ("status" = 'deleted'));
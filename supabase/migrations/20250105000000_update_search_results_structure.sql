-- Update search_results table structure to store case_ids and improve query persistence
-- This migration adds case_id field and modifies the search_results table structure

-- Step 1: Add case_id column to search_results table
ALTER TABLE "public"."search_results" 
ADD COLUMN "case_ids" text[] DEFAULT '{}',
ADD COLUMN "search_count" integer DEFAULT 1,
ADD COLUMN "last_searched_at" timestamp with time zone DEFAULT now();

-- Step 2: Update the results column comment for clarity
COMMENT ON COLUMN "public"."search_results"."results" IS 'Detailed search results with case information';
COMMENT ON COLUMN "public"."search_results"."case_ids" IS 'Array of case IDs found in this search';
COMMENT ON COLUMN "public"."search_results"."search_count" IS 'Number of times this query has been searched';
COMMENT ON COLUMN "public"."search_results"."last_searched_at" IS 'Timestamp of the last search for this query';

-- Step 3: Create index for better performance on case_ids queries
CREATE INDEX IF NOT EXISTS "idx_search_results_case_ids" ON "public"."search_results" USING GIN ("case_ids");
CREATE INDEX IF NOT EXISTS "idx_search_results_task_query" ON "public"."search_results" ("task_id", "query_text");
CREATE INDEX IF NOT EXISTS "idx_search_results_last_searched" ON "public"."search_results" ("task_id", "last_searched_at" DESC);

-- Step 4: Create function to get latest search result for a task
CREATE OR REPLACE FUNCTION get_latest_search_result(task_uuid uuid)
RETURNS TABLE (
    id uuid,
    task_id uuid,
    user_id uuid,
    query_text text,
    results jsonb,
    case_ids text[],
    search_count integer,
    added_to_doc_gen jsonb,
    created_at timestamp with time zone,
    last_searched_at timestamp with time zone
)
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sr.id,
        sr.task_id,
        sr.user_id,
        sr.query_text,
        sr.results,
        sr.case_ids,
        sr.search_count,
        sr.added_to_doc_gen,
        sr.created_at,
        sr.last_searched_at
    FROM search_results sr
    WHERE sr.task_id = task_uuid
    ORDER BY sr.last_searched_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 5: Create function to upsert search results
CREATE OR REPLACE FUNCTION upsert_search_result(
    p_task_id uuid,
    p_user_id uuid,
    p_query_text text,
    p_results jsonb,
    p_case_ids text[]
)
RETURNS uuid
AS $$
DECLARE
    result_id uuid;
BEGIN
    -- Try to update existing record with same task_id and query_text
    UPDATE search_results 
    SET 
        results = p_results,
        case_ids = p_case_ids,
        search_count = search_count + 1,
        last_searched_at = now()
    WHERE task_id = p_task_id AND query_text = p_query_text
    RETURNING id INTO result_id;
    
    -- If no existing record found, insert new one
    IF result_id IS NULL THEN
        INSERT INTO search_results (task_id, user_id, query_text, results, case_ids)
        VALUES (p_task_id, p_user_id, p_query_text, p_results, p_case_ids)
        RETURNING id INTO result_id;
    END IF;
    
    RETURN result_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 6: Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_latest_search_result(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION upsert_search_result(uuid, uuid, text, jsonb, text[]) TO authenticated;
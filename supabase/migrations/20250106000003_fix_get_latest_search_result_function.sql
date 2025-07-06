-- Drop existing function first to avoid return type conflict
DROP FUNCTION IF EXISTS get_latest_search_result(uuid);

-- Recreate get_latest_search_result function to return all required fields
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

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_latest_search_result(uuid) TO authenticated;
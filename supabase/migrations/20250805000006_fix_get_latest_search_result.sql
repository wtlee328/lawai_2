-- Fix get_latest_search_result RPC function to work with new schema

-- Drop the existing function if it exists
DROP FUNCTION IF EXISTS get_latest_search_result(UUID);

-- Create updated function that works with new schema
CREATE OR REPLACE FUNCTION get_latest_search_result(task_uuid UUID)
RETURNS TABLE (
  id UUID,
  task_id UUID,
  user_id UUID,
  query_text JSONB,
  search_mode VARCHAR(20),
  results JSONB,
  case_ids TEXT[],
  search_count INTEGER,
  created_at TIMESTAMPTZ,
  last_searched_at TIMESTAMPTZ,
  added_to_doc_gen JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    sr.id,
    sr.task_id,
    sr.user_id,
    sr.query_text,
    COALESCE(sr.search_mode, 'general'::VARCHAR(20)) as search_mode,
    sr.results,
    sr.case_ids,
    sr.search_count,
    sr.created_at,
    sr.last_searched_at,
    sr.added_to_doc_gen
  FROM search_results sr
  WHERE sr.task_id = task_uuid
  ORDER BY sr.last_searched_at DESC
  LIMIT 1;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_latest_search_result(UUID) TO authenticated;

-- Add comment
COMMENT ON FUNCTION get_latest_search_result IS 'Get the latest search result for a task, compatible with new schema';
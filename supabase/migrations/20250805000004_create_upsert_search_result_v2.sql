-- Create updated upsert function that handles search_mode and JSONB query_text

CREATE OR REPLACE FUNCTION upsert_search_result_v2(
  p_task_id UUID,
  p_user_id UUID,
  p_query_text JSONB,
  p_search_mode VARCHAR(20),
  p_results JSONB,
  p_case_ids TEXT[],
  p_added_to_doc_gen JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
  result_id UUID;
BEGIN
  -- Try to find existing search result with same task_id, user_id, query_text, and search_mode
  SELECT id INTO result_id
  FROM search_results
  WHERE task_id = p_task_id 
    AND user_id = p_user_id 
    AND query_text = p_query_text
    AND search_mode = p_search_mode;

  IF result_id IS NOT NULL THEN
    -- Update existing record
    UPDATE search_results
    SET 
      results = p_results,
      case_ids = p_case_ids,
      added_to_doc_gen = COALESCE(p_added_to_doc_gen, added_to_doc_gen),
      search_count = search_count + 1,
      last_searched_at = NOW()
    WHERE id = result_id;
  ELSE
    -- Insert new record
    INSERT INTO search_results (
      task_id,
      user_id,
      query_text,
      search_mode,
      results,
      case_ids,
      added_to_doc_gen,
      search_count,
      created_at,
      last_searched_at
    ) VALUES (
      p_task_id,
      p_user_id,
      p_query_text,
      p_search_mode,
      p_results,
      p_case_ids,
      COALESCE(p_added_to_doc_gen, '{}'::jsonb),
      1,
      NOW(),
      NOW()
    ) RETURNING id INTO result_id;
  END IF;

  RETURN result_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION upsert_search_result_v2 TO authenticated;
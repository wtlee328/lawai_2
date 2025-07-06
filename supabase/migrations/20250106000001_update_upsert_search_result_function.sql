-- Update upsert_search_result function to handle added_to_doc_gen parameter
CREATE OR REPLACE FUNCTION upsert_search_result(
  p_task_id UUID,
  p_user_id UUID,
  p_query_text TEXT,
  p_results JSONB,
  p_case_ids TEXT[] DEFAULT '{}',
  p_added_to_doc_gen JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
  existing_id UUID;
  result_id UUID;
BEGIN
  -- Check if a search result with the same query already exists for this task
  SELECT id INTO existing_id
  FROM search_results
  WHERE task_id = p_task_id 
    AND user_id = p_user_id 
    AND query_text = p_query_text;

  IF existing_id IS NOT NULL THEN
    -- Update existing record
    UPDATE search_results
    SET 
      results = p_results,
      case_ids = p_case_ids,
      search_count = search_count + 1,
      last_searched_at = NOW(),
      added_to_doc_gen = p_added_to_doc_gen
    WHERE id = existing_id;
    
    result_id := existing_id;
  ELSE
    -- Insert new record
    INSERT INTO search_results (
      task_id, 
      user_id, 
      query_text, 
      results, 
      case_ids, 
      search_count, 
      created_at, 
      last_searched_at,
      added_to_doc_gen
    )
    VALUES (
      p_task_id, 
      p_user_id, 
      p_query_text, 
      p_results, 
      p_case_ids, 
      1, 
      NOW(), 
      NOW(),
      p_added_to_doc_gen
    )
    RETURNING id INTO result_id;
  END IF;

  RETURN result_id;
END;
$$;
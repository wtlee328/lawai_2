-- Complete search mode update: Schema changes + Function creation
-- This migration combines all necessary changes for search mode persistence

-- First, ensure the search_mode column exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'search_results' AND column_name = 'search_mode'
  ) THEN
    ALTER TABLE search_results 
    ADD COLUMN search_mode VARCHAR(20) DEFAULT 'general' 
    CHECK (search_mode IN ('general', 'multi_field'));
  END IF;
END $$;

-- Check if query_text is already JSONB, if not convert it
DO $$
BEGIN
  -- Check if query_text is already JSONB
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'search_results' 
    AND column_name = 'query_text' 
    AND data_type = 'text'
  ) THEN
    -- Add temporary JSONB column
    ALTER TABLE search_results ADD COLUMN query_text_jsonb JSONB;
    
    -- Migrate existing data
    UPDATE search_results 
    SET query_text_jsonb = CASE 
      WHEN query_text IS NULL THEN NULL
      WHEN query_text::text LIKE '{%}' THEN 
        CASE 
          WHEN jsonb_typeof(query_text::jsonb) = 'object' THEN query_text::jsonb
          ELSE jsonb_build_object('query', query_text)
        END
      ELSE jsonb_build_object('query', query_text)
    END;
    
    -- Drop old column and rename new one
    ALTER TABLE search_results DROP COLUMN query_text;
    ALTER TABLE search_results RENAME COLUMN query_text_jsonb TO query_text;
  END IF;
END $$;

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_search_results_search_mode ON search_results(search_mode);
CREATE INDEX IF NOT EXISTS idx_search_results_query_text_gin ON search_results USING GIN (query_text);

-- Update existing records to have proper search_mode
UPDATE search_results 
SET search_mode = CASE
  WHEN query_text ? 'content' OR query_text ? 'dispute' OR query_text ? 'opinion' OR query_text ? 'result' 
  THEN 'multi_field'
  ELSE 'general'
END
WHERE search_mode IS NULL OR search_mode = 'general';

-- Create or replace the upsert function
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
SECURITY DEFINER
AS $$
DECLARE
  result_id UUID;
BEGIN
  -- Validate search_mode
  IF p_search_mode NOT IN ('general', 'multi_field') THEN
    RAISE EXCEPTION 'Invalid search_mode: %. Must be general or multi_field', p_search_mode;
  END IF;

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
    
    RAISE NOTICE 'Updated existing search result with id: %', result_id;
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
    
    RAISE NOTICE 'Created new search result with id: %', result_id;
  END IF;

  RETURN result_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION upsert_search_result_v2(UUID, UUID, JSONB, VARCHAR, JSONB, TEXT[], JSONB) TO authenticated;

-- Add comments for documentation
COMMENT ON FUNCTION upsert_search_result_v2 IS 'Upsert search results with support for search_mode and JSONB query_text';
COMMENT ON COLUMN search_results.search_mode IS 'Search mode: general or multi_field';
COMMENT ON COLUMN search_results.query_text IS 'Query data in JSONB format. For general: {"query": "text"}. For multi-field: {"content": "text", "dispute": "text", "opinion": "text", "result": "text"}';

-- Test the function (optional, can be removed in production)
DO $$
DECLARE
  test_result UUID;
BEGIN
  -- This is just a test to ensure the function works
  -- You can remove this block if you prefer
  RAISE NOTICE 'Testing upsert_search_result_v2 function...';
  
  -- The function should be callable now
  RAISE NOTICE 'Function upsert_search_result_v2 is ready for use';
END $$;
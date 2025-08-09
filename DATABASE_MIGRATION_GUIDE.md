# Database Migration Guide - Search Mode Update

## Issue
The `upsert_search_result_v2` function is not found in the database, causing search results to fail saving.

## Solution Steps

### Step 1: Check Current Database State

Run this query in your Supabase SQL editor to check the current state:

```sql
-- Check if search_mode column exists
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'search_results' 
  AND column_name IN ('query_text', 'search_mode');

-- Check available functions
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name LIKE 'upsert_search_result%';
```

### Step 2: Apply Schema Changes

If the `search_mode` column doesn't exist, run this:

```sql
-- Add search_mode column
ALTER TABLE search_results 
ADD COLUMN search_mode VARCHAR(20) DEFAULT 'general' 
CHECK (search_mode IN ('general', 'multi_field'));

-- Add index
CREATE INDEX IF NOT EXISTS idx_search_results_search_mode ON search_results(search_mode);
```

### Step 3: Convert query_text to JSONB

If `query_text` is still TEXT type, run this:

```sql
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

-- Add GIN index for JSONB
CREATE INDEX IF NOT EXISTS idx_search_results_query_text_gin ON search_results USING GIN (query_text);
```

### Step 4: Create the Function

Copy and paste this entire function into your Supabase SQL editor:

```sql
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

  -- Try to find existing search result
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

-- Grant permissions
GRANT EXECUTE ON FUNCTION upsert_search_result_v2(UUID, UUID, JSONB, VARCHAR, JSONB, TEXT[], JSONB) TO authenticated;
```

### Step 5: Verify the Function

Run this to verify the function was created:

```sql
SELECT 
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'upsert_search_result_v2' AND n.nspname = 'public';
```

### Step 6: Update Existing Data

Set search_mode for existing records:

```sql
UPDATE search_results 
SET search_mode = CASE
  WHEN query_text ? 'content' OR query_text ? 'dispute' OR query_text ? 'opinion' OR query_text ? 'result' 
  THEN 'multi_field'
  ELSE 'general'
END
WHERE search_mode IS NULL OR search_mode = 'general';
```

## Alternative: Use Migration Files

If you prefer to use migration files, run these commands in your terminal:

```bash
# Apply the migrations
supabase db push

# Or if using local development
supabase migration up
```

## Verification

After completing the steps, test the function:

```sql
-- Test query (replace UUIDs with actual values from your database)
SELECT upsert_search_result_v2(
  'your-task-id'::UUID,
  'your-user-id'::UUID,
  '{"query": "test"}'::JSONB,
  'general',
  '[]'::JSONB,
  ARRAY[]::TEXT[],
  '{}'::JSONB
);
```

## Troubleshooting

### If you get permission errors:
```sql
GRANT EXECUTE ON FUNCTION upsert_search_result_v2 TO authenticated;
GRANT EXECUTE ON FUNCTION upsert_search_result_v2 TO anon;
```

### If the function still doesn't work:
1. Check if you're connected to the right database
2. Verify you have the necessary permissions
3. Try dropping and recreating the function
4. Check the Supabase logs for detailed error messages

### Fallback Option:
The frontend code now includes a fallback mechanism that will use the original `upsert_search_result` function if the v2 version is not available, so the application should continue working even if the migration is incomplete.

## Expected Result

After successful migration:
- ✅ `search_mode` column exists with 'general' or 'multi_field' values
- ✅ `query_text` is JSONB type with proper structure
- ✅ `upsert_search_result_v2` function is available
- ✅ Search persistence works for both general and multi-field modes
- ✅ No more JSON strings appearing in general search input
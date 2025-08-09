-- Migration: Add search_mode field and convert query_text to JSONB
-- This migration adds support for multi-field search persistence

-- Add search_mode column to search_results table
ALTER TABLE search_results 
ADD COLUMN search_mode VARCHAR(20) DEFAULT 'general' CHECK (search_mode IN ('general', 'multi_field'));

-- Create a temporary column for the new JSONB data
ALTER TABLE search_results 
ADD COLUMN query_text_jsonb JSONB;

-- Migrate existing data: convert text queries to JSONB format
UPDATE search_results 
SET query_text_jsonb = jsonb_build_object('query', query_text)
WHERE query_text IS NOT NULL;

-- For any existing multi-field searches (if they exist), try to parse JSON
-- This handles cases where query_text might already contain JSON strings
UPDATE search_results 
SET query_text_jsonb = CASE 
  WHEN query_text::text LIKE '{%}' THEN 
    CASE 
      WHEN jsonb_typeof(query_text::jsonb) = 'object' THEN query_text::jsonb
      ELSE jsonb_build_object('query', query_text)
    END
  ELSE jsonb_build_object('query', query_text)
END
WHERE query_text IS NOT NULL;

-- Drop the old column and rename the new one
ALTER TABLE search_results DROP COLUMN query_text;
ALTER TABLE search_results RENAME COLUMN query_text_jsonb TO query_text;

-- Add index on search_mode for better query performance
CREATE INDEX IF NOT EXISTS idx_search_results_search_mode ON search_results(search_mode);

-- Add index on query_text JSONB for better search performance
CREATE INDEX IF NOT EXISTS idx_search_results_query_text_gin ON search_results USING GIN (query_text);

-- Update any existing records to have proper search_mode
-- Detect multi-field searches by checking if query_text has multi-field structure
UPDATE search_results 
SET search_mode = 'multi_field'
WHERE query_text ? 'content' OR query_text ? 'dispute' OR query_text ? 'opinion' OR query_text ? 'result';

-- Ensure all records have a search_mode
UPDATE search_results 
SET search_mode = 'general'
WHERE search_mode IS NULL;

-- Add comment to document the new structure
COMMENT ON COLUMN search_results.search_mode IS 'Search mode: general or multi_field';
COMMENT ON COLUMN search_results.query_text IS 'Query data in JSONB format. For general: {"query": "text"}. For multi-field: {"content": "text", "dispute": "text", "opinion": "text", "result": "text"}';
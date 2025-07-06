-- Add added_to_doc_gen column to search_results table
ALTER TABLE search_results 
ADD COLUMN added_to_doc_gen JSONB DEFAULT NULL;

-- Add comment to explain the column
COMMENT ON COLUMN search_results.added_to_doc_gen IS 'JSON object storing added_to_doc_gen status for each case_id in the search results';

-- Create index for better performance when querying by added_to_doc_gen status
CREATE INDEX IF NOT EXISTS idx_search_results_added_to_doc_gen 
ON search_results USING GIN (added_to_doc_gen);
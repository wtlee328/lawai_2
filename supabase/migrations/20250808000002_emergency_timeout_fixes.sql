-- Emergency timeout fixes for case_2 table

-- Set more aggressive timeout settings for this session
SET statement_timeout = '30s';
SET work_mem = '512MB';
SET maintenance_work_mem = '1GB';

-- Create additional indexes to speed up common queries
-- Index for topic searches (if not exists)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_case_2_topic_gin 
ON case_2 USING gin(to_tsvector('chinese', topic));

-- Index for case_id prefix searches
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_case_2_case_id_prefix 
ON case_2 USING btree(case_id text_pattern_ops);

-- Index for date ordering (most recent first)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_case_2_date_desc 
ON case_2 (date DESC NULLS LAST);

-- Analyze table to update statistics
ANALYZE case_2;

-- Create a lightweight view for common searches
CREATE OR REPLACE VIEW case_2_search_optimized AS
SELECT 
    case_id,
    topic,
    date,
    CASE 
        WHEN length(content) > 1000 THEN left(content, 1000) || '...'
        ELSE content
    END as content_preview,
    summary,
    url,
    dispute,
    opinion,
    result,
    laws,
    court
FROM case_2
WHERE content IS NOT NULL
ORDER BY date DESC;

-- Create a function for timeout-resistant keyword search
CREATE OR REPLACE FUNCTION safe_keyword_search(
    search_query text,
    search_limit int DEFAULT 10
)
RETURNS TABLE (
    case_id text,
    topic text,
    date text,
    content text,
    summary text,
    url text,
    dispute text,
    opinion text,
    result text,
    laws jsonb,
    court text,
    relevance_score float
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Set timeout for this function
    PERFORM set_config('statement_timeout', '15s', true);
    
    -- First try: search case_id and topic only (fastest)
    RETURN QUERY
    SELECT 
        c.case_id,
        c.topic,
        c.date::text,
        c.content,
        c.summary,
        c.url,
        c.dispute,
        c.opinion,
        c.result,
        c.laws,
        c.court,
        0.8::float as relevance_score
    FROM case_2 c
    WHERE 
        c.case_id ILIKE '%' || search_query || '%' OR
        c.topic ILIKE '%' || search_query || '%'
    ORDER BY c.date DESC
    LIMIT search_limit;
    
    -- If no results, don't try content search to avoid timeout
    -- Return empty result set instead
    
END;
$$;

-- Add comment
COMMENT ON FUNCTION safe_keyword_search IS 'Timeout-resistant keyword search that avoids content ILIKE queries';

-- Create indexes for the RPC functions if they don't exist
-- This helps with vector similarity searches
DO $$
BEGIN
    -- Check if HNSW extension is available and create index if needed
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'vector') THEN
        -- Create HNSW index for content embeddings if it doesn't exist
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_case_2_content_embedding_hnsw') THEN
            CREATE INDEX CONCURRENTLY idx_case_2_content_embedding_hnsw 
            ON case_2 USING hnsw (content_embedding vector_cosine_ops) 
            WITH (m = 16, ef_construction = 64);
        END IF;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- If vector extension is not available, skip index creation
        RAISE NOTICE 'Vector extension not available, skipping HNSW index creation';
END;
$$;

-- Update table statistics
ANALYZE case_2;
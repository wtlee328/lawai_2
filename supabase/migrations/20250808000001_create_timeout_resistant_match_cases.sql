-- Create timeout-resistant match_cases function with optimizations

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS match_cases_v2_optimized(vector, float, int);

-- Create optimized match_cases function with timeout resistance
CREATE OR REPLACE FUNCTION match_cases_v2_optimized(
  query_embedding vector(1536),
  match_threshold float DEFAULT 0.7,  -- Higher default threshold
  match_count int DEFAULT 20         -- Lower default count
)
RETURNS TABLE (
  case_id text,
  case_content text,
  case_topic text,
  case_date text,
  court text,
  dispute text,
  opinion text,
  result text,
  url text,
  laws jsonb,
  summary text,
  similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Set statement timeout for this function
  PERFORM set_config('statement_timeout', '30s', true);
  
  -- Set work_mem for better performance
  PERFORM set_config('work_mem', '256MB', true);
  
  RETURN QUERY
  SELECT 
    c.case_id,
    c.content as case_content,
    c.topic as case_topic,
    c.date::text as case_date,
    c.court,
    c.dispute,
    c.opinion,
    c.result,
    c.url,
    c.laws,
    c.summary,
    -- Cosine similarity (1 - cosine distance)
    (1 - (c.content_embedding <=> query_embedding))::float as similarity
  FROM case_2 c
  WHERE 
    c.content_embedding IS NOT NULL AND
    (1 - (c.content_embedding <=> query_embedding)) > match_threshold
  ORDER BY c.content_embedding <=> query_embedding  -- Use distance for ordering (more efficient)
  LIMIT match_count;
END;
$$;

-- Add comment for documentation
COMMENT ON FUNCTION match_cases_v2_optimized IS 'Timeout-resistant vector similarity search function for case_2 table with performance optimizations';
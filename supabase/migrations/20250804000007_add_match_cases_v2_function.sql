-- Migration: Add match_cases_v2 function for general search on case_2 table
-- This function provides semantic search functionality for the case_2 table

CREATE OR REPLACE FUNCTION match_cases_v2(
  query_embedding vector(1536),
  match_threshold float DEFAULT 0.5,
  match_count int DEFAULT 50
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
  similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.case_id,
    c.content as case_content,
    c.topic as case_topic,
    c.date as case_date,
    c.court,
    c.dispute,
    c.opinion,
    c.result,
    c.url,
    c.laws,
    -- Cosine similarity (1 - cosine distance)
    (1 - (c.content_embedding <=> query_embedding)) as similarity
  FROM case_2 c
  WHERE 
    c.content_embedding IS NOT NULL AND
    (1 - (c.content_embedding <=> query_embedding)) > match_threshold
  ORDER BY similarity DESC
  LIMIT match_count;
END;
$$;

-- Create index if it doesn't exist
CREATE INDEX IF NOT EXISTS case_2_content_embedding_hnsw_idx ON case_2 USING hnsw (content_embedding vector_cosine_ops);
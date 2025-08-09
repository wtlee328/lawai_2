-- Create match_cases_v2 function for case_2 table vector similarity search (optimized)
CREATE OR REPLACE FUNCTION match_cases_v2 (
   query_embedding vector(1536),
   match_threshold float DEFAULT 0.5,
   match_count int DEFAULT 10
 )
 RETURNS TABLE (
   case_id text,
   case_topic text,
   case_date date,
   case_content text,
   similarity float
 )
 AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.case_id,
    c.case_topic,
    c.case_date,
    c.case_content,
    (1 - (c.embedding <=> query_embedding)) as similarity
  FROM case_2 c
  WHERE c.embedding IS NOT NULL
  ORDER BY c.embedding <=> query_embedding
  LIMIT match_count;
END;
 $$ language plpgsql stable;

-- Add comment for documentation
COMMENT ON FUNCTION match_cases_v2 IS 'Vector similarity search function for case_2 table using cosine distance (fixed version)';
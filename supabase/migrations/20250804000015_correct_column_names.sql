-- Fix column names to match actual database schema

CREATE OR REPLACE FUNCTION match_cases_multi_field(
  content_embedding vector(1536) DEFAULT NULL,
  dispute_embedding vector(512) DEFAULT NULL,
  opinion_embedding vector(512) DEFAULT NULL,
  result_embedding vector(512) DEFAULT NULL,
  match_threshold float DEFAULT 0.3,
  match_count int DEFAULT 50,
  field_weights jsonb DEFAULT '{"content": 0.4, "dispute": 0.3, "opinion": 0.2, "result": 0.1}'::jsonb,
  ef_search int DEFAULT 100
)
RETURNS TABLE (
  case_id text,
  content text,
  summary text,
  topic text,
  case_date text,
  court text,
  dispute text,
  opinion text,
  result text,
  url text,
  laws jsonb,
  content_similarity float,
  dispute_similarity float,
  opinion_similarity float,
  result_similarity float,
  weighted_similarity float
)
LANGUAGE plpgsql
AS $$
DECLARE
  content_weight float := COALESCE((field_weights->>'content')::float, 0.4);
  dispute_weight float := COALESCE((field_weights->>'dispute')::float, 0.3);
  opinion_weight float := COALESCE((field_weights->>'opinion')::float, 0.2);
  result_weight float := COALESCE((field_weights->>'result')::float, 0.1);
BEGIN
  -- Set ef_search parameter for this session to enable broader search
  PERFORM set_config('hnsw.ef_search', ef_search::text, true);
  
  -- Simple approach: if only content embedding provided, use efficient single-field search
  IF match_cases_multi_field.content_embedding IS NOT NULL AND match_cases_multi_field.dispute_embedding IS NULL AND match_cases_multi_field.opinion_embedding IS NULL AND match_cases_multi_field.result_embedding IS NULL THEN
    RETURN QUERY
    SELECT 
      c.case_id,
      c.content,
      c.summary,
      c.topic,
      c.date::text as case_date,
      c.court,
      c.dispute,
      c.opinion,
      c.result,
      c.url,
      c.laws,
      (1 - (c.content_embedding <=> match_cases_multi_field.content_embedding))::float as content_similarity,
      0.0::float as dispute_similarity,
      0.0::float as opinion_similarity,
      0.0::float as result_similarity,
      (1 - (c.content_embedding <=> match_cases_multi_field.content_embedding))::float as weighted_similarity
    FROM case_2 c
    WHERE 
      c.content_embedding IS NOT NULL
      AND (1 - (c.content_embedding <=> match_cases_multi_field.content_embedding)) > match_threshold
    ORDER BY c.content_embedding <=> match_cases_multi_field.content_embedding
    LIMIT match_count;
  ELSE
    -- For multi-field, use comprehensive approach with ef_search optimization
    RETURN QUERY
    SELECT 
      c.case_id,
      c.content,
      c.summary,
      c.topic,
      c.date::text as case_date,
      c.court,
      c.dispute,
      c.opinion,
      c.result,
      c.url,
      c.laws,
      -- Individual similarity scores
      CASE 
        WHEN match_cases_multi_field.content_embedding IS NOT NULL AND c.content_embedding IS NOT NULL 
        THEN (1 - (c.content_embedding <=> match_cases_multi_field.content_embedding))::float
        ELSE 0.0::float
      END as content_similarity,
      CASE 
        WHEN match_cases_multi_field.dispute_embedding IS NOT NULL AND c.dispute_embedding IS NOT NULL 
        THEN (1 - (c.dispute_embedding <=> match_cases_multi_field.dispute_embedding))::float
        ELSE 0.0::float
      END as dispute_similarity,
      CASE 
        WHEN match_cases_multi_field.opinion_embedding IS NOT NULL AND c.opinion_embedding IS NOT NULL 
        THEN (1 - (c.opinion_embedding <=> match_cases_multi_field.opinion_embedding))::float
        ELSE 0.0::float
      END as opinion_similarity,
      CASE 
        WHEN match_cases_multi_field.result_embedding IS NOT NULL AND c.result_embedding IS NOT NULL 
        THEN (1 - (c.result_embedding <=> match_cases_multi_field.result_embedding))::float
        ELSE 0.0::float
      END as result_similarity,
      -- Weighted combined similarity
      (
        CASE 
          WHEN match_cases_multi_field.content_embedding IS NOT NULL AND c.content_embedding IS NOT NULL 
          THEN content_weight * (1 - (c.content_embedding <=> match_cases_multi_field.content_embedding))
          ELSE 0.0
        END +
        CASE 
          WHEN match_cases_multi_field.dispute_embedding IS NOT NULL AND c.dispute_embedding IS NOT NULL 
          THEN dispute_weight * (1 - (c.dispute_embedding <=> match_cases_multi_field.dispute_embedding))
          ELSE 0.0
        END +
        CASE 
          WHEN match_cases_multi_field.opinion_embedding IS NOT NULL AND c.opinion_embedding IS NOT NULL 
          THEN opinion_weight * (1 - (c.opinion_embedding <=> match_cases_multi_field.opinion_embedding))
          ELSE 0.0
        END +
        CASE 
          WHEN match_cases_multi_field.result_embedding IS NOT NULL AND c.result_embedding IS NOT NULL 
          THEN result_weight * (1 - (c.result_embedding <=> match_cases_multi_field.result_embedding))
          ELSE 0.0
        END
      )::float as weighted_similarity
    FROM case_2 c
    WHERE 
      -- Only process cases that have at least one required embedding
      (match_cases_multi_field.content_embedding IS NULL OR c.content_embedding IS NOT NULL) AND
      (match_cases_multi_field.dispute_embedding IS NULL OR c.dispute_embedding IS NOT NULL) AND
      (match_cases_multi_field.opinion_embedding IS NULL OR c.opinion_embedding IS NOT NULL) AND
      (match_cases_multi_field.result_embedding IS NULL OR c.result_embedding IS NOT NULL) AND
      -- At least one field must meet the threshold
      (
        (match_cases_multi_field.content_embedding IS NOT NULL AND c.content_embedding IS NOT NULL AND 
         (1 - (c.content_embedding <=> match_cases_multi_field.content_embedding)) > match_threshold) OR
        (match_cases_multi_field.dispute_embedding IS NOT NULL AND c.dispute_embedding IS NOT NULL AND 
         (1 - (c.dispute_embedding <=> match_cases_multi_field.dispute_embedding)) > match_threshold) OR
        (match_cases_multi_field.opinion_embedding IS NOT NULL AND c.opinion_embedding IS NOT NULL AND 
         (1 - (c.opinion_embedding <=> match_cases_multi_field.opinion_embedding)) > match_threshold) OR
        (match_cases_multi_field.result_embedding IS NOT NULL AND c.result_embedding IS NOT NULL AND 
         (1 - (c.result_embedding <=> match_cases_multi_field.result_embedding)) > match_threshold)
      )
    ORDER BY weighted_similarity DESC
    LIMIT match_count;
  END IF;
END;
$$;
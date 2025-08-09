-- Fix ambiguous column references in match_cases_multi_field_v3

DROP FUNCTION IF EXISTS match_cases_multi_field_v3;

CREATE OR REPLACE FUNCTION match_cases_multi_field_v3(
  content_embedding vector(1536) DEFAULT NULL,
  dispute_embedding vector(512) DEFAULT NULL,
  opinion_embedding vector(512) DEFAULT NULL,
  result_embedding vector(512) DEFAULT NULL,
  match_threshold float DEFAULT 0.5,
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
  p_content_embedding vector(1536) := match_cases_multi_field_v3.content_embedding;
  p_dispute_embedding vector(512) := match_cases_multi_field_v3.dispute_embedding;
  p_opinion_embedding vector(512) := match_cases_multi_field_v3.opinion_embedding;
  p_result_embedding vector(512) := match_cases_multi_field_v3.result_embedding;
BEGIN
  -- Set ef_search parameter for this session to enable broader search
  PERFORM set_config('hnsw.ef_search', ef_search::text, true);
  
  -- Optimized single-field approach to avoid timeouts
  -- Priority: content > dispute > opinion > result
  
  IF p_content_embedding IS NOT NULL THEN
    -- Content-based search (highest priority)
    RETURN QUERY
    SELECT 
      c.case_id,
      c.content,
      COALESCE(c.summary, '') as summary,
      c.topic,
      c.date::text as case_date,
      COALESCE(c.court, '') as court,
      COALESCE(c.dispute, '') as dispute,
      COALESCE(c.opinion, '') as opinion,
      COALESCE(c.result, '') as result,
      c.url,
      COALESCE(c.laws, '[]'::jsonb) as laws,
      (1 - (c.content_embedding <=> p_content_embedding))::float as content_similarity,
      CASE 
        WHEN p_dispute_embedding IS NOT NULL AND c.dispute_embedding IS NOT NULL 
        THEN (1 - (c.dispute_embedding <=> p_dispute_embedding))::float
        ELSE 0.0::float
      END as dispute_similarity,
      CASE 
        WHEN p_opinion_embedding IS NOT NULL AND c.opinion_embedding IS NOT NULL 
        THEN (1 - (c.opinion_embedding <=> p_opinion_embedding))::float
        ELSE 0.0::float
      END as opinion_similarity,
      CASE 
        WHEN p_result_embedding IS NOT NULL AND c.result_embedding IS NOT NULL 
        THEN (1 - (c.result_embedding <=> p_result_embedding))::float
        ELSE 0.0::float
      END as result_similarity,
      -- Weighted similarity with content as primary
      (
        content_weight * (1 - (c.content_embedding <=> p_content_embedding)) +
        CASE 
          WHEN p_dispute_embedding IS NOT NULL AND c.dispute_embedding IS NOT NULL 
          THEN dispute_weight * (1 - (c.dispute_embedding <=> p_dispute_embedding))
          ELSE 0.0
        END +
        CASE 
          WHEN p_opinion_embedding IS NOT NULL AND c.opinion_embedding IS NOT NULL 
          THEN opinion_weight * (1 - (c.opinion_embedding <=> p_opinion_embedding))
          ELSE 0.0
        END +
        CASE 
          WHEN p_result_embedding IS NOT NULL AND c.result_embedding IS NOT NULL 
          THEN result_weight * (1 - (c.result_embedding <=> p_result_embedding))
          ELSE 0.0
        END
      )::float as weighted_similarity
    FROM case_2 c
    WHERE 
      c.content_embedding IS NOT NULL
      AND (1 - (c.content_embedding <=> p_content_embedding)) > match_threshold
    ORDER BY c.content_embedding <=> p_content_embedding
    LIMIT match_count;
    
  ELSIF p_dispute_embedding IS NOT NULL THEN
    -- Dispute-based search
    RETURN QUERY
    SELECT 
      c.case_id,
      c.content,
      COALESCE(c.summary, '') as summary,
      c.topic,
      c.date::text as case_date,
      COALESCE(c.court, '') as court,
      COALESCE(c.dispute, '') as dispute,
      COALESCE(c.opinion, '') as opinion,
      COALESCE(c.result, '') as result,
      c.url,
      COALESCE(c.laws, '[]'::jsonb) as laws,
      0.0::float as content_similarity,
      (1 - (c.dispute_embedding <=> p_dispute_embedding))::float as dispute_similarity,
      CASE 
        WHEN p_opinion_embedding IS NOT NULL AND c.opinion_embedding IS NOT NULL 
        THEN (1 - (c.opinion_embedding <=> p_opinion_embedding))::float
        ELSE 0.0::float
      END as opinion_similarity,
      CASE 
        WHEN p_result_embedding IS NOT NULL AND c.result_embedding IS NOT NULL 
        THEN (1 - (c.result_embedding <=> p_result_embedding))::float
        ELSE 0.0::float
      END as result_similarity,
      -- Weighted similarity with dispute as primary
      (
        dispute_weight * (1 - (c.dispute_embedding <=> p_dispute_embedding)) +
        CASE 
          WHEN p_opinion_embedding IS NOT NULL AND c.opinion_embedding IS NOT NULL 
          THEN opinion_weight * (1 - (c.opinion_embedding <=> p_opinion_embedding))
          ELSE 0.0
        END +
        CASE 
          WHEN p_result_embedding IS NOT NULL AND c.result_embedding IS NOT NULL 
          THEN result_weight * (1 - (c.result_embedding <=> p_result_embedding))
          ELSE 0.0
        END
      )::float as weighted_similarity
    FROM case_2 c
    WHERE 
      c.dispute_embedding IS NOT NULL
      AND (1 - (c.dispute_embedding <=> p_dispute_embedding)) > match_threshold
    ORDER BY c.dispute_embedding <=> p_dispute_embedding
    LIMIT match_count;
    
  ELSIF p_opinion_embedding IS NOT NULL THEN
    -- Opinion-based search
    RETURN QUERY
    SELECT 
      c.case_id,
      c.content,
      COALESCE(c.summary, '') as summary,
      c.topic,
      c.date::text as case_date,
      COALESCE(c.court, '') as court,
      COALESCE(c.dispute, '') as dispute,
      COALESCE(c.opinion, '') as opinion,
      COALESCE(c.result, '') as result,
      c.url,
      COALESCE(c.laws, '[]'::jsonb) as laws,
      0.0::float as content_similarity,
      0.0::float as dispute_similarity,
      (1 - (c.opinion_embedding <=> p_opinion_embedding))::float as opinion_similarity,
      CASE 
        WHEN p_result_embedding IS NOT NULL AND c.result_embedding IS NOT NULL 
        THEN (1 - (c.result_embedding <=> p_result_embedding))::float
        ELSE 0.0::float
      END as result_similarity,
      -- Weighted similarity with opinion as primary
      (
        opinion_weight * (1 - (c.opinion_embedding <=> p_opinion_embedding)) +
        CASE 
          WHEN p_result_embedding IS NOT NULL AND c.result_embedding IS NOT NULL 
          THEN result_weight * (1 - (c.result_embedding <=> p_result_embedding))
          ELSE 0.0
        END
      )::float as weighted_similarity
    FROM case_2 c
    WHERE 
      c.opinion_embedding IS NOT NULL
      AND (1 - (c.opinion_embedding <=> p_opinion_embedding)) > match_threshold
    ORDER BY c.opinion_embedding <=> p_opinion_embedding
    LIMIT match_count;
    
  ELSIF p_result_embedding IS NOT NULL THEN
    -- Result-based search
    RETURN QUERY
    SELECT 
      c.case_id,
      c.content,
      COALESCE(c.summary, '') as summary,
      c.topic,
      c.date::text as case_date,
      COALESCE(c.court, '') as court,
      COALESCE(c.dispute, '') as dispute,
      COALESCE(c.opinion, '') as opinion,
      COALESCE(c.result, '') as result,
      c.url,
      COALESCE(c.laws, '[]'::jsonb) as laws,
      0.0::float as content_similarity,
      0.0::float as dispute_similarity,
      0.0::float as opinion_similarity,
      (1 - (c.result_embedding <=> p_result_embedding))::float as result_similarity,
      result_weight * (1 - (c.result_embedding <=> p_result_embedding))::float as weighted_similarity
    FROM case_2 c
    WHERE 
      c.result_embedding IS NOT NULL
      AND (1 - (c.result_embedding <=> p_result_embedding)) > match_threshold
    ORDER BY c.result_embedding <=> p_result_embedding
    LIMIT match_count;
    
  ELSE
    -- No embeddings provided, return empty result
    RETURN;
  END IF;
END;
$$;

-- Create comment for documentation
COMMENT ON FUNCTION match_cases_multi_field_v3 IS 'Multi-field semantic search function v3 with ef_search support and fixed ambiguous column references';
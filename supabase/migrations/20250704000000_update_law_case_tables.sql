-- Create a function for full-text search
CREATE OR REPLACE FUNCTION match_cases (
   query_embedding vector(1536), -- Updated embedding size to 1536
   match_threshold float,
   match_count int
 )
 RETURNS TABLE (
   case_id text,
   case_topic text,
   case_date date,
   case_gist text,
   similarity float
 )
 AS $$
 select
   cases.case_id,
   cases.case_topic,
   cases.case_date,
   cases.case_gist,
   1 - (cases.case_gist_embedding <=> query_embedding) as similarity
 from cases
 where 1 - (cases.case_gist_embedding <=> query_embedding) > match_threshold
 order by similarity desc
 limit match_count;
 $$ language sql stable;
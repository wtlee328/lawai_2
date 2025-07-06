-- Drop tables in reverse order of creation to respect foreign key constraints
DROP TABLE IF EXISTS case_keywords;
DROP TABLE IF EXISTS case_subcategory_mapping;
DROP TABLE IF EXISTS cases;
DROP TABLE IF EXISTS subcategories;
DROP TABLE IF EXISTS categories;

-- Drop the match_cases function
DROP FUNCTION IF EXISTS match_cases(query_embedding vector, match_count integer, min_similarity double precision);
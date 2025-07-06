-- Drop function first if it exists
DROP FUNCTION IF EXISTS match_cases;

-- Drop tables in reverse order of dependency
DROP TABLE IF EXISTS case_keywords;
DROP TABLE IF EXISTS case_subcategory_mapping;
DROP TABLE IF EXISTS subcategories;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS cases;
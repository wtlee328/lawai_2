-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA extensions;

-- Table: cases
CREATE TABLE IF NOT EXISTS cases (
    case_id TEXT PRIMARY KEY,
    case_topic TEXT,
    case_date DATE,
    case_gist TEXT,
    case_gist_embedding VECTOR(1536) -- Using a common embedding size, adjust if needed
);

-- Table: categories
CREATE TABLE IF NOT EXISTS categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT UNIQUE
);

-- Table: subcategories
CREATE TABLE IF NOT EXISTS subcategories (
    subcategory_id TEXT PRIMARY KEY,
    subcategory_name TEXT,
    category_id INTEGER REFERENCES categories(category_id)
);

-- Table: case_subcategory_mapping
CREATE TABLE IF NOT EXISTS case_subcategory_mapping (
    case_id TEXT REFERENCES cases(case_id) ON DELETE CASCADE,
    subcategory_id TEXT REFERENCES subcategories(subcategory_id) ON DELETE CASCADE,
    PRIMARY KEY (case_id, subcategory_id)
);

-- Table: case_keywords
CREATE TABLE IF NOT EXISTS case_keywords (
    id SERIAL PRIMARY KEY,
    case_id TEXT REFERENCES cases(case_id) ON DELETE CASCADE,
    keyword TEXT
);

-- Create indexes for faster queries
CREATE INDEX idx_case_topic ON cases(case_topic);
CREATE INDEX idx_keyword ON case_keywords(keyword);
CREATE INDEX idx_subcategory_name ON subcategories(subcategory_name);

-- Create a function for full-text search
CREATE OR REPLACE FUNCTION match_cases (
  query_embedding vector(1536),
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

-- Add RLS policies
ALTER TABLE cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE subcategories ENABLE ROW LEVEL SECURITY;
ALTER TABLE case_subcategory_mapping ENABLE ROW LEVEL SECURITY;
ALTER TABLE case_keywords ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read-only access" ON cases FOR SELECT USING (true);
CREATE POLICY "Allow public read-only access" ON categories FOR SELECT USING (true);
CREATE POLICY "Allow public read-only access" ON subcategories FOR SELECT USING (true);
CREATE POLICY "Allow public read-only access" ON case_subcategory_mapping FOR SELECT USING (true);
CREATE POLICY "Allow public read-only access" ON case_keywords FOR SELECT USING (true);

CREATE POLICY "Allow insert for authenticated users" ON cases FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Allow insert for authenticated users" ON categories FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Allow insert for authenticated users" ON subcategories FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Allow insert for authenticated users" ON case_subcategory_mapping FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Allow insert for authenticated users" ON case_keywords FOR INSERT WITH CHECK (auth.role() = 'authenticated');
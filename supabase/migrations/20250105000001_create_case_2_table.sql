-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA extensions;

-- Create case_2 table for law case embeddings
CREATE TABLE IF NOT EXISTS case_2 (
    id SERIAL PRIMARY KEY,
    case_id TEXT NOT NULL,
    case_topic TEXT,
    case_date DATE,
    case_content TEXT,
    embedding VECTOR(1536)
);

-- Create HNSW index for efficient vector similarity search
CREATE INDEX IF NOT EXISTS case_2_embedding_hnsw_idx 
ON case_2 USING hnsw (embedding vector_cosine_ops);

-- Create additional indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_case_2_case_id ON case_2(case_id);
CREATE INDEX IF NOT EXISTS idx_case_2_case_topic ON case_2(case_topic);
CREATE INDEX IF NOT EXISTS idx_case_2_case_date ON case_2(case_date);

-- Add RLS policies for security
ALTER TABLE case_2 ENABLE ROW LEVEL SECURITY;

-- Allow public read access for case data
CREATE POLICY "Allow public read access" ON case_2 FOR SELECT USING (true);

-- Allow authenticated users to insert data
CREATE POLICY "Allow insert for authenticated users" ON case_2 FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Allow authenticated users to update data
CREATE POLICY "Allow update for authenticated users" ON case_2 FOR UPDATE USING (auth.role() = 'authenticated');

-- Allow authenticated users to delete data
CREATE POLICY "Allow delete for authenticated users" ON case_2 FOR DELETE USING (auth.role() = 'authenticated');

-- Add comments for documentation
COMMENT ON TABLE case_2 IS 'Table for storing law case data with vector embeddings for similarity search';
COMMENT ON COLUMN case_2.case_id IS 'Unique identifier for the law case';
COMMENT ON COLUMN case_2.case_topic IS 'Topic or title of the law case';
COMMENT ON COLUMN case_2.case_date IS 'Date of the law case';
COMMENT ON COLUMN case_2.case_content IS 'Full content of the law case';
COMMENT ON COLUMN case_2.embedding IS 'Vector embedding for similarity search (1536 dimensions)';
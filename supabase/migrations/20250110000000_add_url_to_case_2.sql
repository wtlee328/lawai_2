-- Add URL column to case_2 table
ALTER TABLE case_2 ADD COLUMN url TEXT;

-- Create index for URL column for better query performance
CREATE INDEX idx_case_2_url ON case_2(url);

-- Add comment for documentation
COMMENT ON COLUMN case_2.url IS 'URL link to the original judgment document';
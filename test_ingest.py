import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

# Initialize Supabase client with service role key to bypass RLS
url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")  # Use service role key

if not url or not key:
    print("Error: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set in environment variables")
    exit(1)

supabase: Client = create_client(url, key)

def test_insert():
    try:
        # Data to insert (matching the actual table schema)
        case_data = {
            'case_id': 'test_case_001',
            'case_topic': 'Test Case Topic',
            'case_date': '2025-07-05',
            'case_gist': 'This is a test case gist.',
            'case_gist_embedding': [0.1] * 1536  # Dummy embedding
        }

        print(f"Attempting to insert into 'cases' table with data: {case_data}")

        # Upsert data into the 'cases' table
        response = supabase.table('cases').upsert(case_data).execute()

        print("Insert response:", response)

        if response.data:
            print("\nSuccessfully inserted test data into 'cases' table.")
        else:
            print("\nFailed to insert test data. Response indicates an error:", response.error)

    except Exception as e:
        print(f"\nAn exception occurred: {e}")

if __name__ == "__main__":
    test_insert()
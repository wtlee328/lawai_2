import os
import logging
import os
from dotenv import load_dotenv
from supabase import create_client, Client

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    logging.error("Supabase URL or Key not found in environment variables.")
    exit(1)

logging.info(f"Loaded SUPABASE_URL: {SUPABASE_URL}")
logging.info(f"Loaded SUPABASE_KEY: {SUPABASE_KEY[:5]}...") # Print only first 5 chars for security

try:
    # Initialize Supabase client
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    logging.info("Supabase client initialized successfully.")

    # Test connection to 'cases' table
    try:
        response = supabase.from_('cases').select("case_id").limit(1).execute()
        if response.data:
            logging.info(f"Successfully queried 'cases' table. Found {len(response.data)} record(s).")
        else:
            logging.info("Successfully queried 'cases' table, but no records found.")
    except Exception as e:
        logging.error(f"Error querying 'cases' table: {e}")

    # Test connection to 'categories' table
    try:
        response = supabase.from_('categories').select("category_id").limit(1).execute()
        if response.data:
            logging.info(f"Successfully queried 'categories' table. Found {len(response.data)} record(s).")
        else:
            logging.info("Successfully queried 'categories' table, but no records found.")
    except Exception as e:
        logging.error(f"Error querying 'categories' table: {e}")

    # Test connection to 'subcategories' table
    try:
        response = supabase.from_('subcategories').select("subcategory_id").limit(1).execute()
        if response.data:
            logging.info(f"Successfully queried 'subcategories' table. Found {len(response.data)} record(s).")
        else:
            logging.info("Successfully queried 'subcategories' table, but no records found.")
    except Exception as e:
        logging.error(f"Error querying 'subcategories' table: {e}")

    # Test connection to 'case_subcategory_mapping' table
    try:
        response = supabase.from_('case_subcategory_mapping').select("case_id").limit(1).execute()
        if response.data:
            logging.info(f"Successfully queried 'case_subcategory_mapping' table. Found {len(response.data)} record(s).")
        else:
            logging.info("Successfully queried 'case_subcategory_mapping' table, but no records found.")
    except Exception as e:
        logging.error(f"Error querying 'case_subcategory_mapping' table: {e}")

except Exception as e:
    logging.error(f"An unexpected error occurred during Supabase client initialization or testing: {e}")
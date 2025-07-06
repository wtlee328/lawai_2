import os
import json
import asyncio
import re
from datetime import datetime
from supabase import create_client, Client
from openai import OpenAI
from dotenv import load_dotenv
import logging
from tqdm.asyncio import tqdm_asyncio

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Load environment variables
load_dotenv()

# Supabase and OpenAI credentials
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

logging.info(f"Loaded SUPABASE_URL: {SUPABASE_URL}")
logging.info(f"Loaded SUPABASE_SERVICE_ROLE_KEY: {SUPABASE_SERVICE_ROLE_KEY[:5]}...") # Print only first 5 chars for security

# Initialize Supabase client with service role key to bypass RLS
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

# Initialize Sentence Transformer model
# Using a multilingual model suitable for Chinese text
import time
from functools import wraps

def _retry(max_retries=3, delay_seconds=5):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(max_retries):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    logging.warning(f"Attempt {attempt + 1} failed for {func.__name__}: {e}")
                    if attempt < max_retries - 1:
                        time.sleep(delay_seconds)
                    else:
                        logging.error(f"All {max_retries} retries failed for {func.__name__}")
                        raise
        return wrapper
    return decorator

@_retry(max_retries=3, delay_seconds=5)
def get_embedding_model(model_name='text-embedding-ada-002'):
    try:
        logging.info(f"Initializing OpenAI embedding model: {model_name}")
        client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        logging.info("OpenAI client initialized successfully.")
        return client, model_name
    except Exception as e:
        logging.error(f"Failed to initialize OpenAI client: {e}")
        raise

openai_client, embedding_model_name = get_embedding_model()

async def generate_embedding(text):
    try:
        response = await asyncio.to_thread(openai_client.embeddings.create,
            input=text,
            model=embedding_model_name
        )
        return response.data[0].embedding
    except Exception as e:
        logging.error(f"Error generating embedding with OpenAI: {e}")
        return None

@_retry(max_retries=3, delay_seconds=2)
async def upsert_data(table_name, data):
    try:
        return supabase.table(table_name).upsert(data).execute()
    except Exception as e:
        logging.error(f"Error upserting data to {table_name}: {e}")
        # In a real-world scenario, you might want to handle this more gracefully
        # For example, by adding the failed data to a queue for later processing
        return None

def convert_chinese_date(chinese_date):
    """Convert Chinese date format (民國 XX 年 XX 月 XX 日) to standard date format"""
    if not chinese_date or not isinstance(chinese_date, str):
        return None
    
    # Pattern to match Chinese date format
    pattern = r'民國\s*(\d+)\s*年\s*(\d+)\s*月\s*(\d+)\s*日'
    match = re.search(pattern, chinese_date)
    
    if match:
        minguo_year = int(match.group(1))
        month = int(match.group(2))
        day = int(match.group(3))
        
        # Convert Minguo year to Western year (Minguo year + 1911)
        western_year = minguo_year + 1911
        
        try:
            # Create date object and return in YYYY-MM-DD format
            date_obj = datetime(western_year, month, day)
            return date_obj.strftime('%Y-%m-%d')
        except ValueError:
            logging.warning(f"Invalid date values: {western_year}-{month}-{day}")
            return None
    else:
        # If it's already in a standard format or unrecognized, return as is
        return chinese_date

async def process_case(case_data, jcase_output_map):
    case_id = case_data.get('case_id')
    if not case_id:
        logging.warning("Skipping case with no case_id")
        return

    # 1. Prepare case data
    case_record = {
        'case_id': case_id,
        'case_topic': case_data.get('case_topic'),
        'case_date': convert_chinese_date(case_data.get('case_date')),
        'case_gist': case_data.get('case_gist'),
    }

    # 2. Generate embedding for case_gist
    if case_record['case_gist']:
        embedding = await generate_embedding(case_record['case_gist'])
        if embedding:
            case_record['case_gist_embedding'] = embedding
        else:
            case_record['case_gist_embedding'] = None
    else:
        case_record['case_gist_embedding'] = None

    # 3. Upsert case data
    await upsert_data('cases', case_record)

    # 4. Prepare and upsert keywords
    keywords_data = jcase_output_map.get(case_id, {}).get('keywords', [])
    if keywords_data:
        keyword_records = [{'case_id': case_id, 'keyword': kw} for kw in keywords_data]
        await upsert_data('case_keywords', keyword_records)

    # 5. Prepare and upsert subcategory mapping
    subcategory_ids = jcase_output_map.get(case_id, {}).get('subcategory_ids', [])
    if subcategory_ids:
        mapping_records = [{'case_id': case_id, 'subcategory_id': sub_id} for sub_id in subcategory_ids]
        await upsert_data('case_subcategory_mapping', mapping_records)

async def main():
    # Load data from JSON files
    logging.info("Loading JSON data...")
    with open('/Users/kelvin/Documents/GitHub/lawai_2.0/knowlegebase_crawler/judicial_cases.json', 'r') as f:
        judicial_cases = json.load(f)
    with open('/Users/kelvin/Documents/GitHub/lawai_2.0/knowlegebase_crawler/jcase_output.json', 'r') as f:
        jcase_output = json.load(f)

    logging.info("Processing categories and subcategories...")
    # Prepare and insert category and subcategory data
    categories = []
    subcategories = []
    jcase_output_map = {}

    for category in jcase_output:
        categories.append({
            'category_id': category['category_id'],
            'category_name': category['category_name']
        })
        for subcategory in category['subcategories']:
            subcategories.append({
                'subcategory_id': subcategory['subcategory_id'],
                'subcategory_name': subcategory['subcategory_name'],
                'category_id': category['category_id']
            })
            for case in subcategory['related_case_id']:
                for case_id, keywords in case.items():
                    if case_id not in jcase_output_map:
                        jcase_output_map[case_id] = {'keywords': [], 'subcategory_ids': []}
                    jcase_output_map[case_id]['keywords'].extend(keywords)
                    jcase_output_map[case_id]['subcategory_ids'].append(subcategory['subcategory_id'])

    await upsert_data('categories', categories)
    await upsert_data('subcategories', subcategories)

    logging.info(f"Processing {len(judicial_cases)} cases...")
    # Process all cases concurrently
    tasks = [process_case(case, jcase_output_map) for case in judicial_cases]
    await tqdm_asyncio.gather(*tasks)

    logging.info("Data ingestion complete.")

if __name__ == "__main__":
    asyncio.run(main())
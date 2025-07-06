import requests
from bs4 import BeautifulSoup
import json
import time
import os
import re
from urllib.parse import urlparse, parse_qs, urlencode
from tqdm import tqdm

requests.packages.urllib3.disable_warnings(requests.packages.urllib3.exceptions.InsecureRequestWarning)

def get_case_content(case_url):
    """Fetches and parses the content of a single case page."""
    try:
        response = requests.get(case_url, headers={
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36'
        }, verify=False)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')

        data = {}
        
        # Extract header info
        header_mapping = {
            '裁判字號：': 'case_id',
            '案由摘要：': 'case_summary',
            '裁判日期：': 'case_date',
            '裁判要旨：': 'case_gist'
        }

        # New extraction logic based on the screenshot
        int_table = soup.find('div', class_='int-table')
        if int_table:
            rows = int_table.find_all('div', class_='row')
            for row in rows:
                label_div = row.find('div', class_='col-th')
                value_div = row.find('div', class_='col-td')
                if label_div and value_div:
                    label = label_div.text.strip()
                    value = value_div.text.strip()
                    if label in header_mapping:
                        data[header_mapping[label]] = value

        return data

    except requests.exceptions.RequestException as e:
        print(f"Error fetching {case_url}: {e}")
        return None

def crawl_judicial_website(base_url, start_page=1):
    """Crawls the judicial website starting from the given base URL and page number."""
    page = start_page
    output_filename = 'judicial_cases.json'

    while True:
        url = f"{base_url}&page={page}"
        print(f"Crawling page: {page} at {url}")

        try:
            response = requests.get(url, headers={
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36'
            }, verify=False)
            response.raise_for_status()
            soup = BeautifulSoup(response.text, 'html.parser')

            # Correctly select case links based on the provided screenshot
            case_links = soup.find_all('a', class_='hlTitle_scroll')

            if not case_links:
                print("No more case links found. Ending crawl.")
                break

            page_cases = []
            for link in tqdm(case_links, desc=f"Scraping page {page}"):
                case_url = requests.compat.urljoin(url, link['href'])
                print(f"  - Found case: {case_url}")
                case_data = get_case_content(case_url)
                if case_data:
                    page_cases.append(case_data)
                time.sleep(1)  # Respectful delay

            if page_cases:
                # Load existing data, append new data, and save
                existing_data = []
                if os.path.exists(output_filename):
                    with open(output_filename, 'r', encoding='utf-8') as f:
                        try:
                            existing_data = json.load(f)
                            if not isinstance(existing_data, list):
                                existing_data = []
                        except json.JSONDecodeError:
                            existing_data = []
                
                existing_data.extend(page_cases)
                with open(output_filename, 'w', encoding='utf-8') as f:
                    json.dump(existing_data, f, ensure_ascii=False, indent=4)
                print(f"Page {page} crawled and data updated in {output_filename}")


            # Check for a 'next' page link to decide if we should continue
            next_page_link = soup.find('a', string=re.compile(r'下一頁'))
            if not next_page_link:
                 print("No 'next page' link found. Assuming end of results.")
                 break

            page += 1
            time.sleep(2) # Delay between pages

        except requests.exceptions.RequestException as e:
            print(f"Error crawling page {page}: {e}")
            break
    
    print(f"Crawling finished. Data saved to {output_filename}")

if __name__ == "__main__":
    urls_input = input("Please enter one or more starting URLs from the Taiwanese judicial website, separated by spaces: ")
    urls = urls_input.split()
    for start_url in urls:
        print(f"\nProcessing URL: {start_url}")
        if start_url:
            parsed_url = urlparse(start_url)
            query_params = parse_qs(parsed_url.query)

            start_page = 1
            if 'page' in query_params:
                start_page = int(query_params['page'][0])
                # Don't del, let it be part of the base url and get handled
            elif 'Page' in query_params: # Handling case-insensitivity for 'Page'
                start_page = int(query_params['Page'][0])
                # Don't del

            # Reconstruct the base URL without the page parameter for clean processing
            query_params.pop('page', None)
            query_params.pop('Page', None)
            
            base_url_for_paging = f"{parsed_url.scheme}://{parsed_url.netloc}{parsed_url.path}?{urlencode(query_params, doseq=True)}"
            
            crawl_judicial_website(base_url_for_paging, start_page)


import json
import os

def split_json(input_file, output_dir, chunk_size=100):
    """
    Splits a large JSON file containing a list of objects into smaller files.

    Args:
        input_file (str): Path to the input JSON file.
        output_dir (str): Directory to save the split files.
        chunk_size (int): Number of cases per output file.
    """
    # Create the output directory if it doesn't exist
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"Created directory: {output_dir}")

    # Read the large JSON file
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            all_cases = json.load(f)
        print(f"Successfully loaded {len(all_cases)} cases from {input_file}")
    except FileNotFoundError:
        print(f"Error: Input file not found at {input_file}")
        return
    except json.JSONDecodeError:
        print(f"Error: Could not decode JSON from {input_file}")
        return

    # Split the data and write to new files
    for i in range(0, len(all_cases), chunk_size):
        chunk = all_cases[i:i + chunk_size]
        file_number = (i // chunk_size) + 1
        output_filename = os.path.join(output_dir, f'jcases_{file_number}.json')
        
        with open(output_filename, 'w', encoding='utf-8') as f:
            json.dump(chunk, f, ensure_ascii=False, indent=4)
        
        print(f"Saved {len(chunk)} cases to {output_filename}")

    print("\nSplitting complete.")

if __name__ == '__main__':
    INPUT_JSON_FILE = '/Users/kelvin/Documents/GitHub/lawai_2.0/knowlegebase_crawler/judicial_cases.json'
    OUTPUT_DIRECTORY = '/Users/kelvin/Documents/GitHub/lawai_2.0/knowlegebase_crawler/splitted_jcases'
    
    split_json(INPUT_JSON_FILE, OUTPUT_DIRECTORY)


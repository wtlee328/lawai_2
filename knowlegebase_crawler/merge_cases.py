import json
import copy
import os
import argparse
import sys

def merge_data(a, b):
    """
    Merges dataset 'a' into a deep copy of dataset 'b'.
    This version is robust and handles missing 'subcategories' and 'related_case_id' keys.
    """
    merged_data = copy.deepcopy(b)
    category_map = {cat.get('category_id'): cat for cat in merged_data if cat.get('category_id') is not None}

    for category_a in a:
        cat_id_a = category_a.get('category_id')
        if not cat_id_a:
            continue # Skip categories in 'a' that have no ID

        if cat_id_a in category_map:
            # --- Category exists, merge subcategories ---
            category_merged = category_map[cat_id_a]
            
            # Ensure the merged category has a 'subcategories' list to work with
            category_merged.setdefault('subcategories', [])
                
            subcategory_map = {sub.get('subcategory_id'): sub for sub in category_merged['subcategories'] if sub.get('subcategory_id')}
            
            for subcategory_a in category_a.get('subcategories', []):
                sub_id_a = subcategory_a.get('subcategory_id')
                if not sub_id_a:
                    continue # Skip subcategories in 'a' that have no ID
                
                cases_to_add = subcategory_a.get('related_case_id', [])

                if sub_id_a in subcategory_map:
                    # --- Subcategory exists, merge cases ---
                    subcategory_merged = subcategory_map[sub_id_a]
                    
                    if cases_to_add:
                        # This line safely gets or creates the 'related_case_id' list
                        # on the destination subcategory before adding new cases to it.
                        # IT IS THE SOLUTION TO THE PROBLEM.
                        subcategory_merged.setdefault('related_case_id', []).extend(cases_to_add)
                
                else:
                    # --- New subcategory, add it to the category ---
                    category_merged['subcategories'].append(subcategory_a)
        else:
            # --- New category, add it to the main list ---
            merged_data.append(category_a)
            category_map[cat_id_a] = category_a

    # --- Sorting Logic (made robust with .get()) ---
    def get_subcategory_sort_key(subcategory):
        sid = subcategory.get('subcategory_id', '0-0')
        return [int(p) for p in sid.split('-')]

    merged_data.sort(key=lambda cat: cat.get('category_id', 0))
    for category in merged_data:
        if 'subcategories' in category and category['subcategories']:
            category['subcategories'].sort(key=get_subcategory_sort_key)
            
    return merged_data

def main():
    """
    Main function to handle command-line arguments, file I/O, and orchestration.
    """
    parser = argparse.ArgumentParser(
        description="Merge two JSON datasets (a and b) from the current working directory.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument("--file_a", default="a.json", help="Filename of the source dataset (default: a.json).")
    parser.add_argument("--file_b", default="b.json", help="Filename of the base dataset to merge into (default: b.json).")
    parser.add_argument("--output_file", default="merged_data.json", help="Filename for the merged output file (default: merged_data.json).")

    args = parser.parse_args()
    current_directory = os.getcwd()
    print(f"Operating in directory: {current_directory}\n")

    path_a = os.path.join(current_directory, args.file_a)
    path_b = os.path.join(current_directory, args.file_b)
    path_output = os.path.join(current_directory, args.output_file)

    try:
        print(f"Loading source data from: {path_a}")
        with open(path_a, 'r', encoding='utf-8') as f:
            data_a = json.load(f)

        print(f"Loading base data from: {path_b}")
        with open(path_b, 'r', encoding='utf-8') as f:
            data_b = json.load(f)
            
    except FileNotFoundError as e:
        print(f"Error: Input file not found at '{e.filename}'. Please check the path and filenames.", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Could not decode JSON from a file. Malformed JSON detected.\nDetails: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred during file loading: {e}", file=sys.stderr)
        sys.exit(1)

    print("\nMerging data...")
    final_data = merge_data(data_a, data_b)
    print("Merge complete.")

    try:
        print(f"Saving merged data to: {path_output}")
        with open(path_output, 'w', encoding='utf-8') as f_out:
            json.dump(final_data, f_out, indent=2, ensure_ascii=False)
    except Exception as e:
        print(f"An unexpected error occurred while saving the file: {e}", file=sys.stderr)
        sys.exit(1)
        
    print("\n✅ Success! Merged data has been saved.")


if __name__ == "__main__":
    main()
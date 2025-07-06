
import json

def extract_category_info(input_file, output_file):
    """
    Extracts category and subcategory information from a JSON file.

    Args:
        input_file (str): The path to the input JSON file.
        output_file (str): The path to the output JSON file.
    """
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    extracted_data = []
    for category in data:
        category_info = {
            "category_id": category.get("category_id"),
            "category_name": category.get("category_name"),
            "subcategories": []
        }
        if "subcategories" in category:
            for subcategory in category["subcategories"]:
                subcategory_info = {
                    "subcategory_id": subcategory.get("subcategory_id"),
                    "subcategory_name": subcategory.get("subcategory_name")
                }
                category_info["subcategories"].append(subcategory_info)
        extracted_data.append(category_info)

    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(extracted_data, f, ensure_ascii=False, indent=2)

if __name__ == '__main__':
    extract_category_info(
        '/Users/kelvin/Documents/GitHub/lawai_2.0/knowlegebase_crawler/jcase_merged.json',
        'category_info.json'
    )

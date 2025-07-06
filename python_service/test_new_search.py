#!/usr/bin/env python3
"""
Test script for the new search functionality.
"""

import requests
import json
import sys

def test_new_search_api():
    """Test the new search API endpoint."""
    url = "http://localhost:8000/new-search"
    
    # Test data
    test_query = "房客欠租金不付"
    
    payload = {
        "query": test_query,
        "search_methods": ["hybrid"],
        "filters": {},
        "limit": 5
    }
    
    print(f"Testing new search API with query: '{test_query}'")
    print(f"URL: {url}")
    print(f"Payload: {json.dumps(payload, ensure_ascii=False, indent=2)}")
    print("-" * 50)
    
    try:
        response = requests.post(url, json=payload, timeout=30)
        
        print(f"Status Code: {response.status_code}")
        print(f"Response Headers: {dict(response.headers)}")
        
        if response.status_code == 200:
            data = response.json()
            print("✅ Success!")
            print(f"Response: {json.dumps(data, ensure_ascii=False, indent=2)}")
            
            if data.get('success'):
                results = data.get('results', [])
                print(f"\n📊 Found {len(results)} results:")
                for i, result in enumerate(results[:3], 1):
                    print(f"\n{i}. {result.get('title', 'N/A')}")
                    print(f"   Court: {result.get('court', 'N/A')}")
                    print(f"   Relevance: {result.get('relevance_score', 0):.2%}")
                    print(f"   Method: {result.get('search_method', 'N/A')}")
            else:
                print("❌ API returned success=false")
        else:
            print(f"❌ HTTP Error: {response.status_code}")
            print(f"Response: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print("❌ Connection Error: Could not connect to the server.")
        print("Make sure the Python service is running on http://localhost:8000")
    except requests.exceptions.Timeout:
        print("❌ Timeout Error: Request took too long.")
    except Exception as e:
        print(f"❌ Unexpected Error: {e}")

def test_health_check():
    """Test the health check endpoint."""
    url = "http://localhost:8000/"
    
    print("Testing health check...")
    try:
        response = requests.get(url, timeout=5)
        if response.status_code == 200:
            print("✅ Health check passed")
            print(f"Response: {response.json()}")
            return True
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Health check error: {e}")
        return False

if __name__ == "__main__":
    print("🧪 Testing New Search Functionality")
    print("=" * 50)
    
    # Test health check first
    if test_health_check():
        print("\n" + "=" * 50)
        test_new_search_api()
    else:
        print("\n❌ Server is not responding. Please start the Python service first.")
        sys.exit(1)
    
    print("\n" + "=" * 50)
    print("🏁 Test completed")
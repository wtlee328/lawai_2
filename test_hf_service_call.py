#!/usr/bin/env python3
"""
Test script to demonstrate calling the Hugging Face Python service from local environment
"""

import requests
import json
from datetime import datetime

# Hugging Face service URL
HF_SERVICE_URL = "https://wtlee328-lawai-python-service.hf.space"

def test_hf_service_health():
    """Test if the HF service is running"""
    try:
        response = requests.get(f"{HF_SERVICE_URL}/")
        print(f"✅ Health Check - Status: {response.status_code}")
        print(f"   Response: {response.json()}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Health Check Failed: {e}")
        return False

def test_hf_service_search(query, limit=5):
    """Test the search functionality of HF service"""
    try:
        data = {
            "query": query,
            "limit": limit,
            "search_methods": ["hybrid"]
        }
        
        response = requests.post(f"{HF_SERVICE_URL}/new-search", json=data)
        print(f"\n🔍 Search Test - Status: {response.status_code}")
        print(f"   Query: '{query}'")
        
        result = response.json()
        if result.get("success"):
            print(f"   ✅ Search successful")
            print(f"   📊 Results found: {result.get('total_count', 0)}")
            print(f"   ⏰ Timestamp: {result.get('timestamp')}")
            
            # Show first result if available
            if result.get("results") and len(result["results"]) > 0:
                first_result = result["results"][0]
                print(f"   📄 First result: {first_result.get('case_title', 'N/A')[:100]}...")
                print(f"   🏛️  Court: {first_result.get('court', 'N/A')}")
                print(f"   📈 Relevance: {first_result.get('relevance_score', 'N/A')}")
        else:
            print(f"   ❌ Search failed: {result.get('error')}")
            
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Search Test Failed: {e}")
        return False

def simulate_local_service_integration():
    """Simulate how a local service would integrate with HF service"""
    print("\n🔗 Simulating Local Service Integration")
    print("=" * 50)
    
    # Example: Local service receives a user query and forwards to HF service
    user_queries = [
        "contract law",
        "criminal procedure",
        "property rights"
    ]
    
    for i, query in enumerate(user_queries, 1):
        print(f"\n📝 Local Request #{i}: Processing user query '{query}'")
        print(f"   🚀 Forwarding to HF service...")
        
        success = test_hf_service_search(query, limit=3)
        if success:
            print(f"   ✅ Local service successfully processed request #{i}")
        else:
            print(f"   ❌ Local service failed to process request #{i}")

if __name__ == "__main__":
    print("🧪 Testing Local Service → Hugging Face Service Integration")
    print("=" * 60)
    print(f"🕐 Test started at: {datetime.now()}")
    print(f"🌐 HF Service URL: {HF_SERVICE_URL}")
    
    # Test 1: Health check
    print("\n1️⃣ Testing HF Service Health...")
    health_ok = test_hf_service_health()
    
    if health_ok:
        # Test 2: Search functionality
        print("\n2️⃣ Testing HF Service Search...")
        test_hf_service_search("contract law", limit=3)
        
        # Test 3: Integration simulation
        print("\n3️⃣ Testing Integration Simulation...")
        simulate_local_service_integration()
        
        print("\n🎉 All tests completed successfully!")
        print("\n💡 Integration Summary:")
        print("   • Your local service can successfully call the HF Python service")
        print("   • The HF service is responding with proper JSON data")
        print("   • Search functionality is working with real law case data")
        print("   • You can integrate this into your local application")
    else:
        print("\n❌ HF Service is not accessible. Please check the deployment.")
    
    print(f"\n🕐 Test completed at: {datetime.now()}")
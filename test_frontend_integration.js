#!/usr/bin/env node

// Test script to verify frontend integration with Hugging Face Python service
// This simulates the frontend API calls to ensure everything works correctly

// Using built-in fetch (Node.js 18+)

// Configuration
const HF_API_URL = 'https://wtlee328-lawai-python-service.hf.space';

async function testHealthCheck() {
  console.log('🔍 Testing Health Check...');
  try {
    const response = await fetch(`${HF_API_URL}/`);
    const data = await response.json();
    
    if (response.ok) {
      console.log('✅ Health Check Passed:', data.message);
      return true;
    } else {
      console.log('❌ Health Check Failed:', response.status);
      return false;
    }
  } catch (error) {
    console.log('❌ Health Check Error:', error.message);
    return false;
  }
}

async function testSearchEndpoint() {
  console.log('\n🔍 Testing Search Endpoint...');
  try {
    const searchPayload = {
      query: 'contract law breach of contract',
      search_methods: ['hybrid'],
      filters: {},
      limit: 5
    };
    
    const response = await fetch(`${HF_API_URL}/new-search`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(searchPayload)
    });
    
    const data = await response.json();
    
    if (response.ok && data.success) {
      console.log('✅ Search Endpoint Passed');
      console.log(`   - Found ${data.total_count} results`);
      console.log(`   - Query processed: "${searchPayload.query}"`);
      
      if (data.results && data.results.length > 0) {
        console.log(`   - First result: ${data.results[0].case_name || 'N/A'}`);
      }
      
      return true;
    } else {
      console.log('❌ Search Endpoint Failed:', data.error || 'Unknown error');
      return false;
    }
  } catch (error) {
    console.log('❌ Search Endpoint Error:', error.message);
    return false;
  }
}

async function testFrontendCompatibility() {
  console.log('\n🔍 Testing Frontend Compatibility...');
  
  // Test the exact payload format that the frontend sends
  const frontendPayload = {
    query: 'employment law wrongful termination',
    search_methods: ['hybrid'],
    filters: {},
    limit: 10
  };
  
  try {
    const response = await fetch(`${HF_API_URL}/new-search`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(frontendPayload)
    });
    
    const data = await response.json();
    
    if (response.ok && data.success) {
      console.log('✅ Frontend Compatibility Passed');
      
      // Check if response has all expected fields
      const expectedFields = ['success', 'results', 'total_count'];
      const missingFields = expectedFields.filter(field => !(field in data));
      
      if (missingFields.length === 0) {
        console.log('   - All expected response fields present');
      } else {
        console.log('   - Missing fields:', missingFields);
      }
      
      // Check result structure
      if (data.results && data.results.length > 0) {
        const firstResult = data.results[0];
        const resultFields = ['case_id', 'case_name', 'summary'];
        const presentFields = resultFields.filter(field => field in firstResult);
        console.log(`   - Result fields present: ${presentFields.join(', ')}`);
      }
      
      return true;
    } else {
      console.log('❌ Frontend Compatibility Failed:', data.error || 'Unknown error');
      return false;
    }
  } catch (error) {
    console.log('❌ Frontend Compatibility Error:', error.message);
    return false;
  }
}

async function runAllTests() {
  console.log('🚀 Starting Frontend Integration Tests\n');
  console.log(`📡 Testing API: ${HF_API_URL}\n`);
  
  const results = {
    healthCheck: await testHealthCheck(),
    searchEndpoint: await testSearchEndpoint(),
    frontendCompatibility: await testFrontendCompatibility()
  };
  
  console.log('\n📊 Test Results Summary:');
  console.log('========================');
  Object.entries(results).forEach(([test, passed]) => {
    console.log(`${passed ? '✅' : '❌'} ${test}: ${passed ? 'PASSED' : 'FAILED'}`);
  });
  
  const allPassed = Object.values(results).every(result => result);
  
  console.log('\n🎯 Overall Result:');
  if (allPassed) {
    console.log('✅ ALL TESTS PASSED - Frontend integration is ready!');
    console.log('\n🎉 Your Vue.js app can now successfully call the Hugging Face Python service!');
  } else {
    console.log('❌ SOME TESTS FAILED - Please check the issues above');
  }
  
  return allPassed;
}

// Run tests if this script is executed directly
runAllTests().then(success => {
  process.exit(success ? 0 : 1);
});

export { testHealthCheck, testSearchEndpoint, testFrontendCompatibility, runAllTests };
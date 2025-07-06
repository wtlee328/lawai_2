// Example: How to integrate Hugging Face Python service into your local Vue.js application
// This demonstrates calling the HF service from your frontend

// 1. Direct API call from Vue component
const callHuggingFaceService = async (query, limit = 10) => {
  const HF_SERVICE_URL = 'https://wtlee328-lawai-python-service.hf.space';
  
  try {
    const response = await fetch(`${HF_SERVICE_URL}/new-search`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        query: query,
        limit: limit,
        search_methods: ['hybrid']
      })
    });
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Error calling HF service:', error);
    throw error;
  }
};

// 2. Vue.js composable for HF service integration
const useHuggingFaceSearch = () => {
  const isLoading = ref(false);
  const error = ref(null);
  const results = ref([]);
  
  const searchCases = async (query, options = {}) => {
    isLoading.value = true;
    error.value = null;
    
    try {
      const data = await callHuggingFaceService(query, options.limit);
      
      if (data.success) {
        results.value = data.results;
        return {
          success: true,
          results: data.results,
          totalCount: data.total_count,
          timestamp: data.timestamp
        };
      } else {
        throw new Error(data.error || 'Search failed');
      }
    } catch (err) {
      error.value = err.message;
      results.value = [];
      return {
        success: false,
        error: err.message
      };
    } finally {
      isLoading.value = false;
    }
  };
  
  return {
    isLoading: readonly(isLoading),
    error: readonly(error),
    results: readonly(results),
    searchCases
  };
};

// 3. Example Vue component usage
const ExampleSearchComponent = {
  setup() {
    const { isLoading, error, results, searchCases } = useHuggingFaceSearch();
    const searchQuery = ref('');
    
    const handleSearch = async () => {
      if (!searchQuery.value.trim()) return;
      
      console.log('🔍 Searching via HF service:', searchQuery.value);
      
      const result = await searchCases(searchQuery.value, { limit: 10 });
      
      if (result.success) {
        console.log('✅ Search successful:', result);
        // Handle successful search
      } else {
        console.error('❌ Search failed:', result.error);
        // Handle search error
      }
    };
    
    return {
      searchQuery,
      isLoading,
      error,
      results,
      handleSearch
    };
  },
  
  template: `
    <div class="search-container">
      <div class="search-input">
        <input 
          v-model="searchQuery" 
          @keyup.enter="handleSearch"
          placeholder="Search law cases via HF service..."
          :disabled="isLoading"
        />
        <button @click="handleSearch" :disabled="isLoading || !searchQuery.trim()">
          {{ isLoading ? 'Searching...' : 'Search' }}
        </button>
      </div>
      
      <div v-if="error" class="error">
        ❌ Error: {{ error }}
      </div>
      
      <div v-if="isLoading" class="loading">
        🔄 Searching via Hugging Face service...
      </div>
      
      <div v-if="results.length > 0" class="results">
        <h3>📊 Found {{ results.length }} results</h3>
        <div v-for="result in results" :key="result.case_id" class="result-item">
          <h4>{{ result.case_title || 'Untitled Case' }}</h4>
          <p><strong>Court:</strong> {{ result.court }}</p>
          <p><strong>Relevance:</strong> {{ (result.relevance_score * 100).toFixed(1) }}%</p>
          <p><strong>Method:</strong> {{ result.search_method }}</p>
        </div>
      </div>
    </div>
  `
};

// 4. Integration with your existing store (Pinia)
const useSearchStore = defineStore('search', () => {
  const hfSearchResults = ref([]);
  const localSearchResults = ref([]);
  
  // Method to search using HF service
  const searchViaHuggingFace = async (query) => {
    try {
      const data = await callHuggingFaceService(query);
      if (data.success) {
        hfSearchResults.value = data.results;
        return data;
      }
    } catch (error) {
      console.error('HF search failed:', error);
      throw error;
    }
  };
  
  // Method to search using local service (fallback)
  const searchViaLocalService = async (query) => {
    try {
      const response = await fetch('http://localhost:8000/new-search', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ query, limit: 10 })
      });
      const data = await response.json();
      if (data.success) {
        localSearchResults.value = data.results;
        return data;
      }
    } catch (error) {
      console.error('Local search failed:', error);
      throw error;
    }
  };
  
  // Hybrid search: try HF first, fallback to local
  const hybridSearch = async (query) => {
    try {
      console.log('🚀 Trying HF service first...');
      return await searchViaHuggingFace(query);
    } catch (error) {
      console.log('⚠️ HF service failed, trying local service...');
      return await searchViaLocalService(query);
    }
  };
  
  return {
    hfSearchResults: readonly(hfSearchResults),
    localSearchResults: readonly(localSearchResults),
    searchViaHuggingFace,
    searchViaLocalService,
    hybridSearch
  };
});

// 5. Environment configuration
const config = {
  // Production: Use HF service
  HF_SERVICE_URL: 'https://wtlee328-lawai-python-service.hf.space',
  
  // Development: Use local service
  LOCAL_SERVICE_URL: 'http://localhost:8000',
  
  // Auto-detect environment
  getServiceUrl: () => {
    return process.env.NODE_ENV === 'production' 
      ? config.HF_SERVICE_URL 
      : config.LOCAL_SERVICE_URL;
  }
};

console.log('🔧 Integration examples created!');
console.log('💡 You can now:');
console.log('   1. Use callHuggingFaceService() for direct API calls');
console.log('   2. Use useHuggingFaceSearch() composable in Vue components');
console.log('   3. Integrate with your Pinia store using useSearchStore()');
console.log('   4. Configure environment-based service URLs');
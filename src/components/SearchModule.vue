<script setup lang="ts">
import { ref, computed, nextTick, onMounted, watch } from 'vue';
import { Search } from 'lucide-vue-next';
import { useWorkspaceStore } from '../store/workspace';
import { useAuthStore } from '../store/auth';

// Import number SVG icons


const workspaceStore = useWorkspaceStore();
const authStore = useAuthStore();
const searchQuery = ref('');
const isLoading = ref(false);
const searchHistory = ref<any[]>([]);
const inputRef = ref<HTMLInputElement | null>(null);
const emit = defineEmits(['update:search-progress', 'cases-selection-changed']);

// Search mode selection
const selectedSearchMethod = ref('general');
const availableSearchMethods = [
  { value: 'general', label: '一般搜尋', description: '單一欄位搜尋' },
  { value: 'multi-field', label: '多欄位搜尋', description: '跨越多個欄位進行搜尋' }
];

// Number icon mapping
const numberIcons = ['/0.svg', '/1.svg', '/2.svg', '/3.svg', '/4.svg', '/5.svg', '/6.svg', '/7.svg', '/8.svg', '/9.svg'];

const tabs = [
  { name: 'summary', label: '摘要' },
  { name: 'dispute', label: '爭點' },
  { name: 'opinion', label: '本院見解' },
  { name: 'result', label: '判決結果' },
  { name: 'laws', label: '相關法條' }
];

// Function to get number icons for ranking
const getRankingIcons = (rank: number) => {
  const digits = rank.toString().split('').map(Number);
  return digits.map(digit => numberIcons[digit]);
};

// Task-specific UI state cache to preserve UI across task switches
const taskUIStateCache = ref(new Map());

// Load search state when component mounts or active task changes
onMounted(async () => {
  const currentTaskId = workspaceStore.activeTaskId;
  
  // Try to restore from cache first
  if (currentTaskId && taskUIStateCache.value.has(currentTaskId)) {
    const cachedState = taskUIStateCache.value.get(currentTaskId);
    searchQuery.value = cachedState.searchQuery;
    searchHistory.value = cachedState.searchHistory;
    selectedSearchMethod.value = cachedState.selectedSearchMethod || 'general';
    if (cachedState.multiFieldQuery) {
      multiFieldQuery.value = cachedState.multiFieldQuery;
    }
  } else {
    // Load from database and cache the result
    await loadSearchState();
    if (currentTaskId && (searchHistory.value.length > 0 || searchQuery.value || Object.values(multiFieldQuery.value).some(field => field))) {
      taskUIStateCache.value.set(currentTaskId, {
        searchQuery: searchQuery.value,
        searchHistory: searchHistory.value,
        selectedSearchMethod: selectedSearchMethod.value,
        multiFieldQuery: multiFieldQuery.value
      });
    }
  }
});

// Watch for authentication changes - clear cache when user logs out
watch(() => authStore.isAuthenticated, (isAuthenticated) => {
  if (!isAuthenticated) {
    // Clear all cached UI state when user logs out
    taskUIStateCache.value.clear();
    searchHistory.value = [];
    searchQuery.value = '';
  }
});

// Watch for active task changes
watch(() => workspaceStore.activeTaskId, async (newTaskId, oldTaskId) => {
  // Only reload if the task actually changed (not just switching tabs)
  if (newTaskId && newTaskId !== oldTaskId) {
    // Save current task's UI state before switching
    if (oldTaskId && (searchHistory.value.length > 0 || searchQuery.value || Object.values(multiFieldQuery.value).some(field => field))) {
      taskUIStateCache.value.set(oldTaskId, {
          searchQuery: searchQuery.value,
          searchHistory: searchHistory.value,
          selectedSearchMethod: selectedSearchMethod.value,
          multiFieldQuery: multiFieldQuery.value
        });
    }
    
    // Try to restore UI state from cache first
    if (newTaskId && taskUIStateCache.value.has(newTaskId)) {
      const cachedState = taskUIStateCache.value.get(newTaskId);
      searchQuery.value = cachedState.searchQuery;
      searchHistory.value = cachedState.searchHistory;
      selectedSearchMethod.value = cachedState.selectedSearchMethod || 'general';
      if (cachedState.multiFieldQuery) {
        multiFieldQuery.value = cachedState.multiFieldQuery;
      }
    } else {
      // Only load from database if no cached state exists
      await loadSearchState();
    }
  }
});

// Load search state from store
async function loadSearchState() {
  if (!workspaceStore.activeTaskId) return;
  
  // Load latest search result first to get the correct data for this task
  await workspaceStore.loadSearchHistory(workspaceStore.activeTaskId);
  
  // Check if we have results for this specific task
  const history = workspaceStore.activeTask?.latestSearchHistory;

  if (!history || history.length === 0) {
    // Clear current search result and query if no results for this task
    searchHistory.value = [];
    searchQuery.value = '';
    selectedSearchMethod.value = 'general';
    clearMultiFieldQuery();
    return;
  }
  
  // If no cache exists, always reload from database to ensure fresh state
  // (important for login/logout scenarios)
  
  const latestResult = history[0];
  const queryText = latestResult.query_text;
  const searchMode = latestResult.search_mode || 'general';

  // Set the search method based on the stored search_mode
  selectedSearchMethod.value = searchMode === 'multi_field' ? 'multi-field' : 'general';

  if (typeof queryText === 'object' && queryText !== null) {
    // Handle JSONB format for multi-field or general searches
    if (searchMode === 'multi_field') {
      // Restore multi-field query
      multiFieldQuery.value = {
        content: queryText.content || '',
        dispute: queryText.dispute || '',
        opinion: queryText.opinion || '',
        result: queryText.result || ''
      };
      // Set general search query to empty for multi-field mode
      searchQuery.value = '';
    } else {
      // Handle general search
      searchQuery.value = queryText.query || '';
      clearMultiFieldQuery();
    }
  } else {
    // Handle legacy plain string format (fallback)
    searchQuery.value = queryText || '';
    clearMultiFieldQuery();
  }
  
  searchHistory.value = history.map(search => {
    const resultsWithDocGen = search.results?.map((result: any) => {
      const caseId = result.case_id || result.id;
      const addedToDocGenStatus = search.added_to_doc_gen && caseId 
        ? search.added_to_doc_gen[caseId] 
        : null;
      
      return {
        ...result,
        added_to_doc_gen: addedToDocGenStatus,
        activeTab: 'summary'
      };
    }) || [];

    return {
      query: search.query_text,
      results: resultsWithDocGen,
      total_count: search.results?.length || 0,
      case_ids: search.case_ids,
      search_mode: search.search_mode || 'general'
    };
  });
}

// Update current query in store when user types
function updateQueryInStore() {
  if (workspaceStore.activeTaskId) {
    workspaceStore.updateCurrentQuery(workspaceStore.activeTaskId, searchQuery.value);
  }
}

// Toggle add to document generation status
async function toggleAddToDocGen(historyIndex: number, resultIndex: number) {
  if (searchHistory.value[historyIndex] && searchHistory.value[historyIndex].results) {
    const result = searchHistory.value[historyIndex].results[resultIndex];
    result.added_to_doc_gen = result.added_to_doc_gen === 'y' ? null : 'y';
    
    // Update database with new added_to_doc_gen status
    if (workspaceStore.activeTaskId && searchHistory.value[historyIndex].query) {
      // Create updated added_to_doc_gen map
      const addedToDocGenMap: { [key: string]: string | null } = {};
      searchHistory.value.forEach(search => {
        search.results.forEach((res: any) => {
          if (res.case_id) {
            addedToDocGenMap[res.case_id] = res.added_to_doc_gen;
          }
        });
      });
      
      // Extract case IDs
      const caseIds = searchHistory.value[historyIndex].results.map((res: any) => res.case_id || res.id || '').filter(Boolean);
      
      // Save updated results to database
      const searchMode = searchHistory.value[historyIndex].search_mode || 'general';
      await workspaceStore.saveSearchResults(
        searchHistory.value[historyIndex].query, 
        searchHistory.value[historyIndex].results, 
        caseIds, 
        addedToDocGenMap,
        searchMode
      );
      
      // Emit event to notify parent component about selection change
      emit('cases-selection-changed');
      
      // Update cache with new UI state
      if (workspaceStore.activeTaskId) {
        taskUIStateCache.value.set(workspaceStore.activeTaskId, {
          searchQuery: searchQuery.value,
          searchHistory: searchHistory.value,
          selectedSearchMethod: selectedSearchMethod.value,
          multiFieldQuery: multiFieldQuery.value
        });
      }
    }
  }
}

// Height control
const textareaRows = ref(8);
const isDragging = ref(false);
const dragStartY = ref(0);
const dragStartRows = ref(8);

// Character limit constants
const MAX_CHARS = 2000;

// Computed properties for character count and validation
const characterCount = computed(() => {
  if (selectedSearchMethod.value === 'multi-field') {
    // Calculate total characters across all multi-field inputs
    return Object.values(multiFieldQuery.value).reduce((total, field) => total + (field?.length || 0), 0);
  }
  return searchQuery.value.length;
});
const isOverLimit = computed(() => characterCount.value >= MAX_CHARS);
const displayCount = computed(() => {
  if (selectedSearchMethod.value === 'multi-field') {
    return `總字數：${characterCount.value} / ${MAX_CHARS}`;
  }
  return `${characterCount.value} / ${MAX_CHARS}`;
});

// Watch for character limit and truncate if necessary
function handleInput(event: Event) {
  const target = event.target as HTMLTextAreaElement;
  if (target.value.length > MAX_CHARS) {
    const truncated = target.value.substring(0, MAX_CHARS);
    searchQuery.value = truncated;
    target.value = truncated;
  } else {
    searchQuery.value = target.value;
  }
  
  // Update query in store for persistence
  updateQueryInStore();
}

// Computed property for search button state
const canSearch = computed(() => {
  if (selectedSearchMethod.value === 'multi-field') {
    // For multi-field search, at least one field must have content
    const hasMultiFieldContent = Object.values(multiFieldQuery.value).some(field => field && field.trim().length > 0);
    return !isLoading.value && hasMultiFieldContent;
  }
  // For general search
  return !isLoading.value && searchQuery.value.trim().length > 0 && selectedSearchMethod.value !== '';
});



// Handle keyboard shortcuts
function handleKeydown(event: KeyboardEvent) {
  // Ctrl/Cmd + Enter to search
  if ((event.ctrlKey || event.metaKey) && event.key === 'Enter') {
    event.preventDefault();
    handleSearch();
  }
}

// Height control functions
function startDrag(event: MouseEvent) {
  isDragging.value = true;
  dragStartY.value = event.clientY;
  dragStartRows.value = textareaRows.value;
  document.addEventListener('mousemove', handleDrag);
  document.addEventListener('mouseup', stopDrag);
  event.preventDefault();
}

function handleDrag(event: MouseEvent) {
  if (!isDragging.value) return;
  
  const deltaY = event.clientY - dragStartY.value;
  const rowHeight = 24; // Approximate height per row
  const deltaRows = Math.round(deltaY / rowHeight);
  const newRows = Math.max(3, Math.min(20, dragStartRows.value + deltaRows));
  
  textareaRows.value = newRows;
}

function stopDrag() {
  isDragging.value = false;
  document.removeEventListener('mousemove', handleDrag);
  document.removeEventListener('mouseup', stopDrag);
}



const multiFieldQuery = ref({
  content: '',
  dispute: '',
  opinion: '',
  result: ''
});

// Clear multi-field query function
function clearMultiFieldQuery() {
  multiFieldQuery.value = {
    content: '',
    dispute: '',
    opinion: '',
    result: ''
  };
}

async function handleSearch() {
  if (!canSearch.value) return;
  
  isLoading.value = true;
  
  await nextTick();

  // Initialize search progress
  emit('update:search-progress', { event: 'startSearch', query: searchQuery.value });
  
  try {
      
      // Update progress: Initialize service
      await new Promise(resolve => setTimeout(resolve, 500));
      emit('update:search-progress', { event: 'updateSearchProgress', stepId: 'initialize-service', status: 'completed' });
      
      await new Promise(resolve => setTimeout(resolve, 300));
      emit('update:search-progress', { event: 'updateSearchProgress', stepId: 'execute-search', status: 'processing', details: { method: selectedSearchMethod.value, query: searchQuery.value } });
      
      const isMultiField = selectedSearchMethod.value === 'multi-field';
      const endpoint = isMultiField ? 'multi-field' : 'new-search';
      const apiUrl = `https://wtlee328-multi-field-search-api.hf.space/${endpoint}`;

      let requestBody;
      if (isMultiField) {
        requestBody = {
          query: multiFieldQuery.value,
          limit: 10
        };
      } else {
        requestBody = {
          query: searchQuery.value,
          search_methods: ["hybrid"],
          limit: 10
        };
      }

      const response = await fetch(apiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestBody)
      });
      
      if (!response.ok) {
        emit('update:search-progress', { event: 'updateSearchProgress', stepId: 'execute-search', status: 'error', details: { error: `HTTP ${response.status}` } });
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      
      if (data.success) {
        // Update progress: Search completed
        emit('update:search-progress', { event: 'updateSearchProgress', stepId: 'execute-search', status: 'completed', details: { count: data.total_count } });
        
        await new Promise(resolve => setTimeout(resolve, 400));
        emit('update:search-progress', { event: 'updateSearchProgress', stepId: 'process-results', status: 'processing' });
        
        await new Promise(resolve => setTimeout(resolve, 600));

        // Preserve selected cases from old searches
        const selectedCases = new Map<string, string>();
        searchHistory.value.forEach(search => {
          search.results.forEach((result: any) => {
            if (result.added_to_doc_gen === 'y') {
              selectedCases.set(result.case_id, 'y');
            }
          });
        });

        // Initialize added_to_doc_gen field for each result
        const resultsWithDocGen = data.results.map((result: any) => ({
          ...result,
          added_to_doc_gen: selectedCases.get(result.case_id) || result.added_to_doc_gen || null,
          activeTab: 'summary'
        }));
        
        const newSearchResult = {
          query: isMultiField ? JSON.stringify(multiFieldQuery.value) : searchQuery.value,
          results: resultsWithDocGen,
          total_count: data.total_count,
          query_info: data.query_info
        };

        // Add new search to the beginning of the history
        searchHistory.value.unshift(newSearchResult);

        // Keep only the last 5 searches
        if (searchHistory.value.length > 5) {
          searchHistory.value.pop();
        }
        
        // Extract case IDs from results
        const caseIds = data.results.map((result: any) => result.case_id || result.id || '').filter(Boolean);
        
        // Create added_to_doc_gen object mapping case_id to status
        const addedToDocGenMap: { [key: string]: string | null } = {};
        resultsWithDocGen.forEach((result: any) => {
          if (result.case_id) {
            addedToDocGenMap[result.case_id] = result.added_to_doc_gen;
          }
        });
        
        // Save search results to database with proper search mode
        if (workspaceStore.activeTaskId) {
          const searchMode = isMultiField ? 'multi_field' : 'general';
          const queryForSaving = isMultiField ? multiFieldQuery.value : searchQuery.value;
          
          await workspaceStore.saveSearchResults(queryForSaving, data.results, caseIds, addedToDocGenMap, searchMode);
          
          // Update cache with new search results
          taskUIStateCache.value.set(workspaceStore.activeTaskId, {
            searchQuery: searchQuery.value,
            searchHistory: searchHistory.value,
            selectedSearchMethod: selectedSearchMethod.value,
            multiFieldQuery: multiFieldQuery.value
          });
        }
        
        // Update progress: Processing completed
        emit('update:search-progress', { event: 'updateSearchProgress', stepId: 'process-results', status: 'completed', details: { count: data.results.length } });
        
        await new Promise(resolve => setTimeout(resolve, 300));
        emit('update:search-progress', { event: 'updateSearchProgress', stepId: 'return-results', status: 'completed', details: { count: data.results.length } });
      } else {
        emit('update:search-progress', { event: 'updateSearchProgress', stepId: 'execute-search', status: 'error', details: { error: 'Search failed' } });
        throw new Error('Search failed');
      }
  } catch (error) {
    // Show error state
    const errorResult = {
      error: true,
      message: error instanceof Error ? error.message : '搜索失敗，請稍後再試'
    };
    searchHistory.value.unshift(errorResult);
  } finally {
    isLoading.value = false;
  }
}



// Generate Judicial Yuan URL for case details
function generateJudicialUrl(caseId: string, decisionDate?: string): string {
  if (!caseId) return '#';
  
  // Base URL for Judicial Yuan
  const baseUrl = 'https://judgment.judicial.gov.tw/FJUD/';
  
  // Parse case ID to extract components
  // Example: "最高法院 112 年度台上字第 2881 號 民事判決"
  const caseIdMatch = caseId.match(/(\S+)\s+(\d+)\s+年度(\S+)字第\s*(\d+)\s*號/);
  
  if (!caseIdMatch) {
    // Fallback to simple search if parsing fails
    return `${baseUrl}default.aspx?jud=${encodeURIComponent(caseId)}`;
  }
  
  const [, court, year, caseType, caseNumber] = caseIdMatch;
  
  // Map court names to codes
  const courtCodeMap: { [key: string]: string } = {
    '最高法院': 'TPSV',
    '臺灣高等法院': 'TPH',
    '臺灣臺北地方法院': 'TPD',
    '臺灣新北地方法院': 'PCD',
    '臺灣士林地方法院': 'SLD',
    '臺灣桃園地方法院': 'TYD',
    '臺灣新竹地方法院': 'SCD',
    '臺灣苗栗地方法院': 'MLD',
    '臺灣臺中地方法院': 'TCD',
    '臺灣彰化地方法院': 'CHD',
    '臺灣南投地方法院': 'NTD',
    '臺灣雲林地方法院': 'ULD',
    '臺灣嘉義地方法院': 'CYD',
    '臺灣臺南地方法院': 'TND',
    '臺灣高雄地方法院': 'KSD',
    '臺灣屏東地方法院': 'PTD',
    '臺灣臺東地方法院': 'TTD',
    '臺灣花蓮地方法院': 'HLD',
    '臺灣宜蘭地方法院': 'ILD',
    '臺灣基隆地方法院': 'KLD',
    '臺灣澎湖地方法院': 'PHD',
    '福建金門地方法院': 'KMD',
    '福建連江地方法院': 'LCD',
    '智慧財產及商業法院': 'IPC',
    '最高行政法院': 'TPA',
    '臺北高等行政法院': 'TPB',
    '臺中高等行政法院': 'TCB',
    '高雄高等行政法院': 'KSB'
  };
  
  const courtCode = courtCodeMap[court] || 'TPSV'; // Default to Supreme Court
  
  // Format decision date to YYYYMMDD
  let formattedDate = '';
  if (decisionDate) {
    // Parse standard date format (YYYY-MM-DD)
    const date = new Date(decisionDate);
    if (!isNaN(date.getTime())) {
      formattedDate = date.toISOString().slice(0, 10).replace(/-/g, '');
    }
  }
  
  // Use current date as fallback
  if (!formattedDate) {
    formattedDate = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  }
  
  // Construct the URL according to the specified format
  const dataUrl = `${baseUrl}data.aspx?ty=JD&id=${courtCode}%2c${year}%2c${caseType}%2c${caseNumber}%2c${formattedDate}%2c1`;
  
  return dataUrl;
}

// 暴露方法給父組件使用
defineExpose({
  loadSearchState
})
</script>

<template>
  <div>
    <!-- Enhanced Search Input Container -->
    <div class="mb-6">
      <!-- Input Box with Integrated Title -->
      <div class="bg-white dark:bg-gray-900 rounded-xl shadow-lg border border-gray-200 dark:border-0 overflow-hidden transition-all duration-300 hover:shadow-xl">
        <!-- Title Header -->
        <div class="bg-gradient-to-r from-blue-50 to-purple-50 dark:from-gray-800 dark:to-gray-800 px-6 py-4 border-b border-gray-200 dark:border-0 flex justify-between items-center">
          <h2 class="text-lg font-semibold text-blue-700 dark:text-white flex items-center gap-2">
            <Search class="w-5 h-5 text-blue-700 dark:text-white" />
            裁判書搜索
          </h2>
          <!-- Search Mode Selection -->
          <div class="flex items-center gap-2">
            <div class="relative inline-flex bg-gray-200 dark:bg-gray-700 rounded-lg p-1">
              <!-- Animated background indicator -->
              <div 
                class="absolute top-1 bottom-1 bg-gradient-to-r from-blue-400 to-blue-500 rounded-md shadow-sm transition-all duration-300 ease-out"
                :style="{
                  left: `calc(${(availableSearchMethods.findIndex(m => m.value === selectedSearchMethod) / availableSearchMethods.length) * 99}% + 4px)`,
                  width: `calc(${100 / availableSearchMethods.length}% - 8px)`
                }"
              ></div>
              <button
                v-for="method in availableSearchMethods" 
                :key="method.value"
                @click="selectedSearchMethod = method.value"
                :class="[
                  'relative z-10 px-3 py-1.5 text-xs font-medium rounded-md transition-all duration-200',
                  selectedSearchMethod === method.value
                    ? 'text-white'
                    : 'text-gray-600 dark:text-gray-200 hover:text-blue-600 dark:hover:text-white'
                ]"
                :title="method.description"
              >
                {{ method.label }}
              </button>
            </div>
          </div>
        </div>
        <!-- Input Area -->
        <div class="relative">
          <!-- General Search Input -->
          <textarea
            v-if="selectedSearchMethod === 'general'"
            ref="inputRef"
            :value="searchQuery"
            @input="handleInput"
            placeholder="請輸入您的搜索內容...

提示：
• 描述您要搜索的內容
• 使用關鍵詞進行搜索
• 直接輸入案例

快捷鍵：Ctrl/Cmd + Enter 搜尋"
            @keydown="handleKeydown"
            :rows="textareaRows"
            class="w-full pl-6 pr-20 py-4 bg-transparent border-0 focus:outline-none resize-none text-sm leading-relaxed text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-300"
          ></textarea>

          <!-- Multi-field Search Inputs -->
          <div v-if="selectedSearchMethod === 'multi-field'" class="p-6 space-y-4">
            <!-- First Row: Content and Dispute -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <!-- Content Field -->
              <div class="group">
                <div class="flex items-center gap-3 mb-3">
                  <div class="w-8 h-8 bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg flex items-center justify-center shadow-sm">
                    <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                    </svg>
                  </div>
                  <div>
                    <h3 class="text-sm font-semibold text-gray-800 dark:text-gray-200">判決內容</h3>
                    <p class="text-xs text-gray-500 dark:text-gray-400">搜尋判決書的主要內容</p>
                  </div>
                </div>
                <textarea 
                  v-model="multiFieldQuery.content" 
                  placeholder="例如：不符契約約定要求、違約責任、損害賠償..."
                  class="w-full px-4 py-3 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200 resize-none text-sm leading-relaxed text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 group-hover:bg-gray-100 dark:group-hover:bg-gray-750"
                  rows="3"
                ></textarea>
              </div>

              <!-- Dispute Field -->
              <div class="group">
                <div class="flex items-center gap-3 mb-3">
                  <div class="w-8 h-8 bg-gradient-to-br from-orange-500 to-orange-600 rounded-lg flex items-center justify-center shadow-sm">
                    <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 6l3 1m0 0l-3 9a5.002 5.002 0 006.001 0M6 7l3 9M6 7l6-2m6 2l3-1m-3 1l-3 9a5.002 5.002 0 006.001 0M18 7l3 9m-3-9l-6-2m0-2v2m0 16V5m0 16l-3-9m3 9l3-9" />
                    </svg>
                  </div>
                  <div>
                    <h3 class="text-sm font-semibold text-gray-800 dark:text-gray-200">爭點查詢</h3>
                    <p class="text-xs text-gray-500 dark:text-gray-400">搜尋案件的主要爭議點</p>
                  </div>
                </div>
                <textarea 
                  v-model="multiFieldQuery.dispute" 
                  placeholder="例如：契約解釋、責任歸屬、賠償範圍..."
                  class="w-full px-4 py-3 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent transition-all duration-200 resize-none text-sm leading-relaxed text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 group-hover:bg-gray-100 dark:group-hover:bg-gray-750"
                  rows="3"
                ></textarea>
              </div>
            </div>

            <!-- Second Row: Opinion and Result -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <!-- Opinion Field -->
              <div class="group">
                <div class="flex items-center gap-3 mb-3">
                  <div class="w-8 h-8 bg-gradient-to-br from-green-500 to-green-600 rounded-lg flex items-center justify-center shadow-sm">
                    <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z M8 5a2 2 0 012-2h4a2 2 0 012 2v0a2 2 0 01-2 2H10a2 2 0 01-2-2v0z" />
                    </svg>
                  </div>
                  <div>
                    <h3 class="text-sm font-semibold text-gray-800 dark:text-gray-200">法院見解</h3>
                    <p class="text-xs text-gray-500 dark:text-gray-400">搜尋法院的裁判意見</p>
                  </div>
                </div>
                <textarea 
                  v-model="multiFieldQuery.opinion" 
                  placeholder="例如：法院認為、本院見解、依法判斷..."
                  class="w-full px-4 py-3 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent transition-all duration-200 resize-none text-sm leading-relaxed text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 group-hover:bg-gray-100 dark:group-hover:bg-gray-750"
                  rows="3"
                ></textarea>
              </div>

              <!-- Result Field -->
              <div class="group">
                <div class="flex items-center gap-3 mb-3">
                  <div class="w-8 h-8 bg-gradient-to-br from-purple-500 to-purple-600 rounded-lg flex items-center justify-center shadow-sm">
                    <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
                    </svg>
                  </div>
                  <div>
                    <h3 class="text-sm font-semibold text-gray-800 dark:text-gray-200">判決結果</h3>
                    <p class="text-xs text-gray-500 dark:text-gray-400">搜尋最終的判決結果</p>
                  </div>
                </div>
                <textarea 
                  v-model="multiFieldQuery.result" 
                  placeholder="例如：駁回上訴、准予離婚、賠償金額..."
                  class="w-full px-4 py-3 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all duration-200 resize-none text-sm leading-relaxed text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 group-hover:bg-gray-100 dark:group-hover:bg-gray-750"
                  rows="3"
                ></textarea>
              </div>
            </div>

            <!-- Multi-field Search Tips and Actions -->
            <div class="bg-gradient-to-r from-blue-50 to-purple-50 dark:from-gray-800 dark:to-gray-800 rounded-lg p-4 border border-blue-100 dark:border-gray-700">
              <div class="flex items-start justify-between">
                <div class="flex items-start gap-3">
                  <div class="w-5 h-5 text-blue-500 dark:text-blue-400 mt-0.5">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                  <div>
                    <h4 class="text-sm font-medium text-blue-800 dark:text-blue-300 mb-1">多欄位搜尋提示</h4>
                    <ul class="text-xs text-blue-700 dark:text-blue-400 space-y-1">
                      <li>• 可以只填寫部分欄位進行搜尋</li>
                      <li>• 系統會根據各欄位的相關性進行智能匹配</li>
                      <li>• 使用關鍵詞或短句效果更佳</li>
                    </ul>
                  </div>
                </div>
                <!-- Clear All Button -->
                <button
                  @click="clearMultiFieldQuery"
                  v-if="Object.values(multiFieldQuery).some(field => field && field.trim())"
                  class="px-3 py-1.5 text-xs font-medium text-gray-600 dark:text-gray-400 hover:text-red-600 dark:hover:text-red-400 bg-white dark:bg-gray-700 hover:bg-red-50 dark:hover:bg-red-900/20 border border-gray-200 dark:border-gray-600 hover:border-red-200 dark:hover:border-red-800 rounded-md transition-all duration-200 flex items-center gap-1.5"
                  title="清除所有欄位"
                >
                  <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                  清除
                </button>
              </div>
            </div>
          </div>
          
          <!-- Height Resize Handle -->
          <div 
            @mousedown="startDrag"
            :class="[
              'absolute right-0 bottom-0 w-4 h-4 cursor-ns-resize transition-all duration-200',
              isDragging ? 'opacity-80' : 'opacity-60 hover:opacity-100'
            ]"
            title="拖拽調整高度"
          >
            <!-- Diagonal lines pattern -->
            <svg class="w-full h-full" viewBox="0 0 16 16" fill="none">
              <path d="M16 0L0 16" stroke="currentColor" stroke-width="1" class="text-gray-400 dark:text-gray-400" />
              <path d="M16 6L6 16" stroke="currentColor" stroke-width="1" class="text-gray-400 dark:text-gray-400" />
              <path d="M16 12L12 16" stroke="currentColor" stroke-width="1" class="text-gray-400 dark:text-gray-400" />
            </svg>
          </div>
        </div>
        
        <!-- Footer: Character Count, Search Mode & Tips -->
        <div class="px-6 py-3 bg-gray-50 dark:bg-gray-800 border-t border-gray-200 dark:border-0">
          <!-- Top row: Character count and search mode -->
          <div class="flex justify-between items-center">
            <span class="font-medium text-gray-500 dark:text-gray-300 text-xs">
              字數：{{ displayCount }}
              <span v-if="isOverLimit" class="ml-2 text-red-500">已達字數上限</span>
            </span>
            <!-- Search Button -->
            <button
              @click="handleSearch"
              :disabled="!canSearch"
              :title="isLoading ? '搜尋中...' : '開始搜尋 (Ctrl/Cmd + Enter)'"
              :class="[
                'p-2 rounded-full font-semibold transition-all duration-200 flex items-center justify-center shadow-md w-10 h-10',
                !canSearch
                  ? 'bg-gray-300 dark:bg-gray-700 text-gray-500 dark:text-gray-300 cursor-not-allowed'
                  : 'bg-gradient-to-r from-blue-400 to-blue-500 hover:from-blue-500 hover:to-blue-600 text-white shadow-lg hover:shadow-xl transform hover:scale-105'
              ]"
            >
              <Search class="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>
    </div>



    <!-- Search Results -->
    <div v-if="searchHistory.length > 0 && !isLoading" class="mt-6 space-y-8">
      <div v-for="(searchResult, historyIndex) in searchHistory" :key="historyIndex">
        <!-- Error State -->
        <div v-if="searchResult.error" class="bg-white dark:bg-gray-900 rounded-xl shadow-lg border border-red-200 dark:border-0 overflow-hidden">
          <div class="bg-gradient-to-r from-red-50 to-pink-50 dark:from-gray-800 dark:to-gray-800 px-6 py-4 border-b border-red-200 dark:border-0">
            <h3 class="text-lg font-semibold text-red-700 dark:text-white flex items-center gap-2">
              <div class="w-3 h-3 bg-red-500 rounded-full"></div>
              搜索錯誤
            </h3>
          </div>
          <div class="p-6">
            <p class="text-red-600 dark:text-gray-200">{{ searchResult.message }}</p>
          </div>
        </div>
        
        <!-- Success Results -->
        <div v-else class="bg-white dark:bg-gray-900 rounded-xl shadow-lg border border-gray-200 dark:border-0 overflow-hidden">
          <!-- Results Header -->
          <div class="bg-gradient-to-r from-blue-50 to-purple-50 dark:from-gray-800 dark:to-gray-800 px-6 py-4 border-b border-gray-200 dark:border-0" :class="{'grayscale': historyIndex > 0}">
            <div class="flex justify-between items-center">
              <h3 class="text-lg font-semibold text-blue-700 dark:text-white flex items-center gap-2">
                <div class="w-3 h-3 bg-gradient-to-r from-blue-500 to-purple-500 rounded-full"></div>
                搜索結果
              </h3>
              <span class="text-sm text-blue-600 dark:text-gray-200 bg-blue-100 dark:bg-gray-700 px-3 py-1 rounded-full">
                共找到 {{ searchResult.total_count }} 個結果
              </span>
            </div>
          </div>
          
          <!-- Results Content -->
          <div class="p-6">
            <div v-if="searchResult.results && searchResult.results.length > 0" class="space-y-6">
              <div v-for="(result, index) in searchResult.results" :key="result.case_id" :class="{
                'grayscale': historyIndex > 0 && result.added_to_doc_gen !== 'y',
                // Added to doc gen styles (highest priority)
                'bg-green-50 dark:bg-gray-800 border-green-300 dark:border-0 ring-2 ring-green-200 dark:ring-gray-500': result.added_to_doc_gen === 'y',
                // Regular relevance-based styles
                'bg-blue-50 dark:bg-gray-800 border-blue-200 dark:border-0': result.added_to_doc_gen !== 'y' && Math.round(result.relevance_score * 100) > 90,
                'bg-blue-100 bg-opacity-60 dark:bg-gray-800 border-blue-100 dark:border-0': result.added_to_doc_gen !== 'y' && Math.round(result.relevance_score * 100) >= 85 && Math.round(result.relevance_score * 100) <= 90,
                'bg-blue-100 bg-opacity-30 dark:bg-gray-800 border-blue-100 border-opacity-50 dark:border-0': result.added_to_doc_gen !== 'y' && Math.round(result.relevance_score * 100) >= 80 && Math.round(result.relevance_score * 100) < 85,
                'bg-gray-50 dark:bg-gray-800 border-gray-200 dark:border-0': result.added_to_doc_gen !== 'y' && Math.round(result.relevance_score * 100) < 80
              }" class="p-6 rounded-lg hover:shadow-md transition-all duration-200 border relative">
                <!-- Case Header -->
                <div class="flex justify-between items-start mb-4">
                  <div class="flex-1">
                    <h4 class="font-semibold text-lg text-gray-800 dark:text-white">
                      {{ result.case_id }}
                    </h4>
                    <div class="flex items-center gap-4 text-sm text-gray-600 dark:text-gray-300">
                      <span class="flex items-center gap-1">
                        <div class="w-2 h-2 bg-gradient-to-r from-blue-500 to-purple-500 rounded-full"></div>
                        {{ result.court }}
                      </span>
                      <span v-if="result.date_decided">
                        {{ new Date(result.date_decided).toLocaleDateString('zh-TW') }}
                      </span>
                      <span class="text-xs bg-blue-100 dark:bg-gray-700 text-blue-600 dark:text-gray-200 px-2 py-1 rounded">
                        {{ result.search_method }}
                      </span>
                    </div>
                  </div>
                  <div class="flex items-center gap-2 ml-4">
                    <div class="text-right">
                      <div class="text-xs text-gray-500 dark:text-gray-300">相關性</div>
                      <div class="text-sm font-semibold text-blue-500 dark:text-gray-200">
                        {{ Math.round(result.relevance_score * 100) }}%
                      </div>
                    </div>
                    <div class="flex items-center gap-0">
                      <img 
                        v-for="(icon, iconIndex) in getRankingIcons(index + 1)" 
                        :key="iconIndex" 
                        :src="icon" 
                        alt="" 
                        class="w-6 h-6"
                      />
                    </div>
                  </div>
                </div>
                
                <!-- Case Content -->
                <div class="space-y-3">
                  <!-- Tab Headers -->
                  <div class="border-b border-gray-200 dark:border-gray-700">
                      <nav class="-mb-px flex space-x-4" aria-label="Tabs">
                          <button v-for="tab in tabs" :key="tab.name" @click="result.activeTab = tab.name" :class="[
                              result.activeTab === tab.name
                                  ? 'border-blue-500 text-blue-600'
                                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300',
                              'whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm'
                          ]">
                              {{ tab.label }}
                          </button>
                      </nav>
                  </div>

                  <!-- Tab Content -->
                  <div class="pt-4">
                      <div v-if="result.activeTab === 'summary'" class="bg-white dark:bg-gray-900 p-4 rounded-lg border mb-4">
                        <p class="text-gray-900 dark:text-white text-sm leading-relaxed">
                          {{ result.summary || '無摘要資訊' }}
                        </p>
                      </div>
                      <div v-if="result.activeTab === 'dispute'" class="bg-white dark:bg-gray-900 p-4 rounded-lg border mb-4">
                        <p class="text-gray-900 dark:text-white text-sm leading-relaxed">
                          {{ result.dispute || '無爭點資訊' }}
                        </p>
                      </div>
                      <div v-if="result.activeTab === 'opinion'" class="bg-white dark:bg-gray-900 p-4 rounded-lg border mb-4">
                        <p class="text-gray-900 dark:text-white text-sm leading-relaxed">
                          {{ result.opinion || '無本院見解資訊' }}
                        </p>
                      </div>
                      <div v-if="result.activeTab === 'result'" class="bg-white dark:bg-gray-900 p-4 rounded-lg border mb-4">
                        <p class="text-gray-900 dark:text-white text-sm leading-relaxed">
                          {{ result.result || '無判決結果資訊' }}
                        </p>
                      </div>
                      <div v-if="result.activeTab === 'laws'" class="bg-white dark:bg-gray-900 p-4 rounded-lg border mb-4">
                        <ul class="list-disc list-inside text-gray-900 dark:text-white text-sm leading-relaxed">
                          <li v-for="law in result.laws" :key="law">{{ law }}</li>
                        </ul>
                        <p v-if="!result.laws || result.laws.length === 0">無相關法條資訊</p>
                      </div>
                  </div>
                </div>
                
                <!-- Case Actions -->
                <div :class="{
                  'border-t-green-200 dark:border-t-gray-500': result.added_to_doc_gen === 'y',
                  'border-t-blue-200 dark:border-t-gray-500': result.added_to_doc_gen !== 'y' && Math.round(result.relevance_score * 100) > 90,
                  'border-t-blue-100 dark:border-t-gray-500': result.added_to_doc_gen !== 'y' && Math.round(result.relevance_score * 100) >= 85 && Math.round(result.relevance_score * 100) <= 90,
                  'border-t-blue-50 dark:border-t-gray-500': result.added_to_doc_gen !== 'y' && Math.round(result.relevance_score * 100) >= 80 && Math.round(result.relevance_score * 100) < 85,
                  'border-t-gray-200 dark:border-t-gray-500': result.added_to_doc_gen !== 'y' && Math.round(result.relevance_score * 100) < 80
                }" class="mt-4 pt-4 border-t">
                  <div class="flex justify-between items-center">
                    <a :href="generateJudicialUrl(result.case_id, result.date_decided)" target="_blank" class="text-sm font-medium text-blue-500 dark:text-gray-200 hover:text-blue-600 dark:hover:text-white hover:underline">
                      查看全文 →
                    </a>
                    <button 
                      @click="toggleAddToDocGen(historyIndex, index)"
                      :class="{
                        'bg-green-500 hover:bg-green-600 text-white': result.added_to_doc_gen === 'y',
                        'bg-gray-200 hover:bg-gray-300 text-gray-700 dark:bg-gray-700 dark:hover:bg-gray-600 dark:text-gray-200': result.added_to_doc_gen !== 'y'
                      }"
                      class="text-sm font-medium px-3 py-1.5 rounded-lg transition-colors duration-200 flex items-center gap-1"
                    >
                      <span v-if="result.added_to_doc_gen === 'y'">✓</span>
                      <span v-else>+</span>
                      {{ result.added_to_doc_gen === 'y' ? '已加入文件生成' : '加入到文件生成' }}
                    </button>
                  </div>
                </div>
              </div>
            </div>
            
            <!-- No Results -->
            <div v-else class="text-center py-12">
              <div class="text-gray-400 dark:text-gray-300 mb-4">
                <Search class="w-16 h-16 mx-auto mb-4 opacity-50" />
                <p class="text-lg font-medium">沒有找到相關結果</p>
                <p class="text-sm mt-2">請嘗試使用不同的關鍵詞或調整搜索條件</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script setup lang="ts">
import { ref, computed, nextTick, onMounted, watch } from 'vue';
import { Search } from 'lucide-vue-next';
import { useWorkspaceStore } from '../store/workspace';
import { useAuthStore } from '../store/auth';

const workspaceStore = useWorkspaceStore();
const authStore = useAuthStore();
const searchQuery = ref('');
const isLoading = ref(false);
const searchResult = ref<any>(null);
const inputRef = ref<HTMLInputElement | null>(null);
const emit = defineEmits(['update:search-progress']);

// Search mode selection
const selectedSearchMethod = ref('hybrid');
const availableSearchMethods = [
  { value: 'hybrid', label: '混合搜尋', description: '結合語意和關鍵字搜尋' },
  { value: 'semantic', label: '語意搜尋', description: '基於語意理解的智能搜尋' },
  { value: 'keyword', label: '關鍵字搜尋', description: '精確的關鍵字匹配搜尋' },
  { value: 'category', label: '類別搜尋', description: '按法律類別分類搜尋' }
];

// Task-specific UI state cache to preserve UI across task switches
const taskUIStateCache = ref(new Map());

// Load search state when component mounts or active task changes
onMounted(async () => {
  const currentTaskId = workspaceStore.activeTaskId;
  
  // Try to restore from cache first
  if (currentTaskId && taskUIStateCache.value.has(currentTaskId)) {
    const cachedState = taskUIStateCache.value.get(currentTaskId);
    searchQuery.value = cachedState.searchQuery;
    searchResult.value = cachedState.searchResult;
    selectedSearchMethod.value = cachedState.selectedSearchMethod || 'hybrid';
  } else {
    // Load from database and cache the result
    await loadSearchState();
    if (currentTaskId && (searchResult.value || searchQuery.value)) {
      taskUIStateCache.value.set(currentTaskId, {
        searchQuery: searchQuery.value,
        searchResult: searchResult.value,
        selectedSearchMethod: selectedSearchMethod.value
      });
    }
  }
});

// Watch for authentication changes - clear cache when user logs out
watch(() => authStore.isAuthenticated, (isAuthenticated) => {
  if (!isAuthenticated) {
    // Clear all cached UI state when user logs out
    taskUIStateCache.value.clear();
    searchResult.value = null;
    searchQuery.value = '';
  }
});

// Watch for active task changes
watch(() => workspaceStore.activeTaskId, async (newTaskId, oldTaskId) => {
  // Only reload if the task actually changed (not just switching tabs)
  if (newTaskId && newTaskId !== oldTaskId) {
    // Save current task's UI state before switching
    if (oldTaskId && (searchResult.value || searchQuery.value)) {
      taskUIStateCache.value.set(oldTaskId, {
          searchQuery: searchQuery.value,
          searchResult: searchResult.value,
          selectedSearchMethod: selectedSearchMethod.value
        });
    }
    
    // Try to restore UI state from cache first
    if (newTaskId && taskUIStateCache.value.has(newTaskId)) {
      const cachedState = taskUIStateCache.value.get(newTaskId);
      searchQuery.value = cachedState.searchQuery;
      searchResult.value = cachedState.searchResult;
      selectedSearchMethod.value = cachedState.selectedSearchMethod || 'hybrid';
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
  await workspaceStore.loadLatestSearchResult(workspaceStore.activeTaskId);
  
  // Check if we have results for this specific task
  const hasResultsForCurrentTask = workspaceStore.activeTask?.latestSearchResult?.results?.length > 0;
  
  if (!hasResultsForCurrentTask) {
    // Clear current search result and query if no results for this task
    searchResult.value = null;
    searchQuery.value = '';
    return;
  }
  
  // If we already have search results displayed and they match the current task, don't reload
  // only if we have cached state (to avoid unnecessary reloads during task switching)
  if (searchResult.value && searchResult.value.results?.length > 0 && 
      taskUIStateCache.value.has(workspaceStore.activeTaskId)) {
    // Just update the query text
    const currentQuery = workspaceStore.getCurrentQuery(workspaceStore.activeTaskId);
    searchQuery.value = currentQuery;
    return;
  }
  
  // If no cache exists, always reload from database to ensure fresh state
  // (important for login/logout scenarios)
  
  // Get current query text (either from input or latest search)
  const currentQuery = workspaceStore.getCurrentQuery(workspaceStore.activeTaskId);
  searchQuery.value = currentQuery;
  
  // Load search results if available
  if (workspaceStore.activeTask?.latestSearchResult) {
    const latestResult = workspaceStore.activeTask.latestSearchResult;
    
    // Initialize added_to_doc_gen field for loaded results
    const resultsWithDocGen = latestResult.results?.map((result: any) => {
      // Get added_to_doc_gen status from database for this case_id
      const caseId = result.case_id || result.id;
      const addedToDocGenStatus = latestResult.added_to_doc_gen && caseId 
        ? latestResult.added_to_doc_gen[caseId] 
        : null;
      
      return {
        ...result,
        added_to_doc_gen: addedToDocGenStatus
      };
    }) || [];
    
    searchResult.value = {
      query: latestResult.query_text,
      results: resultsWithDocGen,
      total_count: latestResult.results?.length || 0,
      case_ids: latestResult.case_ids
    };
  }
}

// Update current query in store when user types
function updateQueryInStore() {
  if (workspaceStore.activeTaskId) {
    workspaceStore.updateCurrentQuery(workspaceStore.activeTaskId, searchQuery.value);
  }
}

// Toggle add to document generation status
async function toggleAddToDocGen(index: number) {
  if (searchResult.value && searchResult.value.results) {
    const result = searchResult.value.results[index];
    result.added_to_doc_gen = result.added_to_doc_gen === 'y' ? null : 'y';
    
    // Update database with new added_to_doc_gen status
    if (workspaceStore.activeTaskId && searchResult.value.query) {
      // Create updated added_to_doc_gen map
      const addedToDocGenMap: { [key: string]: string | null } = {};
      searchResult.value.results.forEach((res: any) => {
        if (res.case_id) {
          addedToDocGenMap[res.case_id] = res.added_to_doc_gen;
        }
      });
      
      // Extract case IDs
      const caseIds = searchResult.value.results.map((res: any) => res.case_id || res.id || '').filter(Boolean);
      
      // Save updated results to database
      await workspaceStore.saveSearchResults(
        searchResult.value.query, 
        searchResult.value.results, 
        caseIds, 
        addedToDocGenMap
      );
      
      // Update cache with new UI state
      if (workspaceStore.activeTaskId) {
        taskUIStateCache.value.set(workspaceStore.activeTaskId, {
          searchQuery: searchQuery.value,
          searchResult: searchResult.value,
          selectedSearchMethod: selectedSearchMethod.value
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
const characterCount = computed(() => searchQuery.value.length);
const isOverLimit = computed(() => characterCount.value >= MAX_CHARS);
const displayCount = computed(() => `${characterCount.value} / ${MAX_CHARS}`);

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



async function handleSearch() {
  if (!canSearch.value) return;
  
  isLoading.value = true;
  searchResult.value = null;
  
  await nextTick();

  // Initialize search progress
  emit('update:search-progress', { event: 'startSearch', query: searchQuery.value });
  
  try {
      
      // Update progress: Initialize service
      await new Promise(resolve => setTimeout(resolve, 500));
      emit('update:search-progress', { event: 'updateSearchProgress', stepId: 'initialize-service', status: 'completed' });
      
      await new Promise(resolve => setTimeout(resolve, 300));
      emit('update:search-progress', { event: 'updateSearchProgress', stepId: 'execute-search', status: 'processing', details: { method: 'hybrid', query: searchQuery.value } });
      
      // Call the new search API endpoint
      const apiUrl = import.meta.env.VITE_PYTHON_API_URL || 'http://localhost:8000';
      const response = await fetch(`${apiUrl}/new-search`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          query: searchQuery.value,
          search_methods: [selectedSearchMethod.value],
          filters: {},
          limit: 10
        })
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
        // Initialize added_to_doc_gen field for each result
        const resultsWithDocGen = data.results.map((result: any) => ({
          ...result,
          added_to_doc_gen: result.added_to_doc_gen || null
        }));
        
        searchResult.value = {
          query: searchQuery.value,
          results: resultsWithDocGen,
          total_count: data.total_count,
          query_info: data.query_info
        };
        
        // Extract case IDs from results
        const caseIds = data.results.map((result: any) => result.case_id || result.id || '').filter(Boolean);
        
        // Create added_to_doc_gen object mapping case_id to status
        const addedToDocGenMap: { [key: string]: string | null } = {};
        resultsWithDocGen.forEach((result: any) => {
          if (result.case_id) {
            addedToDocGenMap[result.case_id] = result.added_to_doc_gen;
          }
        });
        
        // Save search results to database
        if (workspaceStore.activeTaskId) {
          await workspaceStore.saveSearchResults(searchQuery.value, data.results, caseIds, addedToDocGenMap);
          
          // Update cache with new search results
          taskUIStateCache.value.set(workspaceStore.activeTaskId, {
            searchQuery: searchQuery.value,
            searchResult: searchResult.value,
            selectedSearchMethod: selectedSearchMethod.value
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
    searchResult.value = {
      error: true,
      message: error instanceof Error ? error.message : '搜索失敗，請稍後再試'
    };
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
</script>

<template>
  <div>
    <!-- Enhanced Search Input Container -->
    <div class="mb-6">
      <!-- Input Box with Integrated Title -->
      <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg border border-gray-200 dark:border-gray-700 overflow-hidden transition-all duration-300 hover:shadow-xl">
        <!-- Title Header -->
        <div class="bg-gradient-to-r from-blue-50 to-purple-50 dark:from-blue-900/20 dark:to-purple-900/20 px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <h2 class="text-lg font-semibold text-blue-700 dark:text-blue-300 flex items-center gap-2">
            <Search class="w-5 h-5 text-blue-700 dark:text-blue-300" />
            裁判書搜索
          </h2>
        </div>
        <!-- Input Area -->
        <div class="relative">
          <textarea
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
            class="w-full pl-6 pr-20 py-4 bg-transparent border-0 focus:outline-none resize-none text-sm leading-relaxed text-gray-900 dark:text-gray-100 placeholder-gray-500 dark:placeholder-gray-400"
          ></textarea>
          
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
              <path d="M16 0L0 16" stroke="currentColor" stroke-width="1" class="text-gray-400 dark:text-gray-500" />
              <path d="M16 6L6 16" stroke="currentColor" stroke-width="1" class="text-gray-400 dark:text-gray-500" />
              <path d="M16 12L12 16" stroke="currentColor" stroke-width="1" class="text-gray-400 dark:text-gray-500" />
            </svg>
          </div>
          
          <!-- Action Buttons (Inside Input Box) -->
          <div class="absolute right-5 bottom-3 flex items-center gap-2">
 

            
            <button
              @click="handleSearch"
              :disabled="!canSearch"
              :title="isLoading ? '搜尋中...' : '開始搜尋 (Ctrl/Cmd + Enter)'"
              :class="[
                'p-2 rounded-full font-semibold transition-all duration-200 flex items-center justify-center shadow-md w-10 h-10',
                !canSearch
                  ? 'bg-gray-300 dark:bg-gray-600 text-gray-500 dark:text-gray-400 cursor-not-allowed'
                  : 'bg-gradient-to-r from-blue-400 to-blue-500 hover:from-blue-500 hover:to-blue-600 text-white shadow-lg hover:shadow-xl transform hover:scale-105'
              ]"
            >
              <Search class="w-5 h-5" />
            </button>
          </div>
        </div>
        
        <!-- Footer: Character Count, Search Mode & Tips -->
        <div class="px-6 py-3 bg-gray-50 dark:bg-gray-700/50 border-t border-gray-200 dark:border-gray-600">
          <!-- Top row: Character count and search mode -->
          <div class="flex justify-between items-center mb-3">
            <span class="font-medium text-gray-500 dark:text-gray-400 text-xs">
              字數：{{ displayCount }}
              <span v-if="isOverLimit" class="ml-2 text-red-500">已達字數上限</span>
            </span>
            <!-- Search Mode Selection -->
             <div class="flex items-center gap-2">
               <div class="inline-flex bg-gray-200 dark:bg-gray-700 rounded-lg p-1 gap-1">
                <button
                  v-for="method in availableSearchMethods" 
                  :key="method.value"
                  @click="selectedSearchMethod = method.value"
                  :class="[
                    'px-3 py-1.5 text-xs font-medium rounded-md transition-all duration-200',
                    selectedSearchMethod === method.value
                      ? 'bg-gradient-to-r from-blue-400 to-blue-500 text-white shadow-sm'
                      : 'text-gray-600 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400 hover:bg-blue-50 dark:hover:bg-gray-700'
                  ]"
                  :title="method.description"
                >
                  {{ method.label }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>



    <!-- Search Results -->
    <div v-if="searchResult && !isLoading" class="mt-6">
      <!-- Error State -->
      <div v-if="searchResult.error" class="bg-white dark:bg-gray-800 rounded-xl shadow-lg border border-red-200 dark:border-red-700 overflow-hidden">
        <div class="bg-gradient-to-r from-red-50 to-pink-50 dark:from-red-900/20 dark:to-pink-900/20 px-6 py-4 border-b border-red-200 dark:border-red-700">
          <h3 class="text-lg font-semibold text-red-700 dark:text-red-300 flex items-center gap-2">
            <div class="w-3 h-3 bg-red-500 rounded-full"></div>
            搜索錯誤
          </h3>
        </div>
        <div class="p-6">
          <p class="text-red-600 dark:text-red-400">{{ searchResult.message }}</p>
        </div>
      </div>
      
      <!-- Success Results -->
      <div v-else class="bg-white dark:bg-gray-800 rounded-xl shadow-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
        <!-- Results Header -->
        <div class="bg-gradient-to-r from-blue-50 to-purple-50 dark:from-blue-900/20 dark:to-purple-900/20 px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <div class="flex justify-between items-center">
            <h3 class="text-lg font-semibold text-blue-700 dark:text-blue-300 flex items-center gap-2">
              <div class="w-3 h-3 bg-gradient-to-r from-blue-500 to-purple-500 rounded-full"></div>
              搜索結果
            </h3>
            <span class="text-sm text-blue-600 dark:text-blue-400 bg-blue-100 dark:bg-blue-900/30 px-3 py-1 rounded-full">
              共找到 {{ searchResult.total_count }} 個結果
            </span>
          </div>
        </div>
        
        <!-- Results Content -->
        <div class="p-6">
          <div v-if="searchResult.results && searchResult.results.length > 0" class="space-y-6">
            <div v-for="(result, index) in searchResult.results" :key="result.case_id" :class="{
              // Added to doc gen styles (highest priority)
              'bg-green-50 dark:bg-green-900/20 border-green-300 dark:border-green-600 ring-2 ring-green-200 dark:ring-green-700': result.added_to_doc_gen === 'y',
              // Regular relevance-based styles
              'bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-700': result.added_to_doc_gen !== 'y' && Math.round(result.relevance_score * 100) > 90,
              'bg-blue-100 bg-opacity-60 dark:bg-blue-900/15 border-blue-100 dark:border-blue-800': result.added_to_doc_gen !== 'y' && Math.round(result.relevance_score * 100) >= 85 && Math.round(result.relevance_score * 100) <= 90,
              'bg-blue-100 bg-opacity-30 dark:bg-blue-900/10 border-blue-100 border-opacity-50 dark:border-blue-900': result.added_to_doc_gen !== 'y' && Math.round(result.relevance_score * 100) >= 80 && Math.round(result.relevance_score * 100) < 85,
              'bg-gray-50 dark:bg-gray-800/20 border-gray-200 dark:border-gray-700': result.added_to_doc_gen !== 'y' && Math.round(result.relevance_score * 100) < 80
            }" class="p-6 rounded-lg hover:shadow-md transition-all duration-200 border relative">
              <!-- Case Header -->
              <div class="flex justify-between items-start mb-4">
                <div class="flex-1">
                  <div class="flex items-center gap-2 mb-1">
                    <h4 class="font-semibold text-lg text-gray-800 dark:text-gray-200">
                      {{ result.title || result.case_number }}
                    </h4>
                    <span v-if="result.added_to_doc_gen === 'y'" class="text-xs bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300 px-2 py-1 rounded-full font-medium">
                      ✓ 已加入文件生成
                    </span>
                  </div>
                  <div class="flex items-center gap-4 text-sm text-gray-600 dark:text-gray-400">
                    <span class="flex items-center gap-1">
                      <div class="w-2 h-2 bg-gradient-to-r from-blue-500 to-purple-500 rounded-full"></div>
                      {{ result.court }}
                    </span>
                    <span v-if="result.date_decided">
                      {{ new Date(result.date_decided).toLocaleDateString('zh-TW') }}
                    </span>
                    <span class="text-xs bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 px-2 py-1 rounded">
                      {{ result.search_method }}
                    </span>
                  </div>
                </div>
                <div class="flex items-center gap-2 ml-4">
                  <div class="text-right">
                    <div class="text-xs text-gray-500 dark:text-gray-400">相關性</div>
                    <div class="text-sm font-semibold text-blue-500 dark:text-blue-400">
                      {{ Math.round(result.relevance_score * 100) }}%
                    </div>
                  </div>
                  <div :class="{
                    'bg-gradient-to-r from-blue-500 to-blue-700': Math.round(result.relevance_score * 100) > 90,
                    'bg-gradient-to-r from-blue-400 to-blue-600': Math.round(result.relevance_score * 100) >= 85 && Math.round(result.relevance_score * 100) <= 90,
                    'bg-gradient-to-r from-blue-300 to-blue-500': Math.round(result.relevance_score * 100) >= 80 && Math.round(result.relevance_score * 100) < 85,
                    'bg-gradient-to-r from-blue-200 to-blue-400': Math.round(result.relevance_score * 100) < 80
                  }" class="w-12 h-12 rounded-full flex items-center justify-center text-white font-bold text-sm">
                    {{ index + 1 }}
                  </div>
                </div>
              </div>
              
              <!-- Case Content -->
              <div class="space-y-3">
                <div v-if="result.summary" :class="{
                   'border-blue-200 dark:border-blue-700': Math.round(result.relevance_score * 100) > 90,
                   'border-blue-100 dark:border-blue-800': Math.round(result.relevance_score * 100) >= 85 && Math.round(result.relevance_score * 100) <= 90,
                   'border-blue-50 dark:border-blue-900': Math.round(result.relevance_score * 100) >= 80 && Math.round(result.relevance_score * 100) < 85,
                   'border-gray-200 dark:border-gray-700': Math.round(result.relevance_score * 100) < 80
                 }" class="bg-white dark:bg-gray-800 p-4 rounded-lg border mb-4">
                  <div class="text-xs text-gray-500 dark:text-gray-400 mb-2">案件摘要</div>
                  <p class="text-gray-900 dark:text-gray-100 text-sm leading-relaxed">
                    {{ result.summary }}
                  </p>
                </div>
              </div>
              
              <!-- Case Actions -->
              <div :class="{
                'border-t-green-200 dark:border-t-green-700': result.added_to_doc_gen === 'y',
                'border-t-blue-200 dark:border-t-blue-700': result.added_to_doc_gen !== 'y' && Math.round(result.relevance_score * 100) > 90,
                'border-t-blue-100 dark:border-t-blue-800': result.added_to_doc_gen !== 'y' && Math.round(result.relevance_score * 100) >= 85 && Math.round(result.relevance_score * 100) <= 90,
                'border-t-blue-50 dark:border-t-blue-900': result.added_to_doc_gen !== 'y' && Math.round(result.relevance_score * 100) >= 80 && Math.round(result.relevance_score * 100) < 85,
                'border-t-gray-200 dark:border-t-gray-700': result.added_to_doc_gen !== 'y' && Math.round(result.relevance_score * 100) < 80
              }" class="mt-4 pt-4 border-t">
                <div class="flex justify-between items-center">
                  <div class="text-xs text-gray-500 dark:text-gray-400">
                    案件編號：{{ result.case_id }}
                  </div>
                  <div class="flex items-center gap-3">
                    <button 
                      @click="toggleAddToDocGen(index)"
                      :class="{
                        'bg-green-500 hover:bg-green-600 text-white': result.added_to_doc_gen === 'y',
                        'bg-gray-200 hover:bg-gray-300 text-gray-700 dark:bg-gray-600 dark:hover:bg-gray-500 dark:text-gray-200': result.added_to_doc_gen !== 'y'
                      }"
                      class="text-sm font-medium px-3 py-1.5 rounded-lg transition-colors duration-200 flex items-center gap-1"
                    >
                      <span v-if="result.added_to_doc_gen === 'y'">✓</span>
                      <span v-else>+</span>
                      {{ result.added_to_doc_gen === 'y' ? '已加入文件生成' : '加入到文件生成' }}
                    </button>
                    <a :href="generateJudicialUrl(result.case_id, result.date_decided)" target="_blank" class="text-sm font-medium text-blue-500 dark:text-blue-400 hover:text-blue-600 dark:hover:text-blue-500 hover:underline">
                      查看詳情 →
                    </a>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <!-- No Results -->
          <div v-else class="text-center py-12">
            <div class="text-gray-400 dark:text-gray-500 mb-4">
              <Search class="w-16 h-16 mx-auto mb-4 opacity-50" />
              <p class="text-lg font-medium">沒有找到相關結果</p>
              <p class="text-sm mt-2">請嘗試使用不同的關鍵詞或調整搜索條件</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
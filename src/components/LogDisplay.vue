<template>
  <div class="log-display p-6 bg-gradient-to-br from-slate-50 to-slate-100 dark:from-gray-800 dark:to-gray-900 rounded-xl shadow-lg" :class="isExpanded ? 'min-h-80 max-h-screen overflow-hidden' : 'h-80 overflow-hidden'">
    <div class="flex items-center justify-between mb-6">
      <div class="flex items-center space-x-3">
        <div class="w-3 h-3 bg-gradient-to-r from-blue-500 to-purple-500 rounded-full"></div>
        <h3 class="text-xl text-blue-700 dark:text-blue-300">搜索進度</h3>
      </div>
      <button
        v-if="searchSteps.length > 0"
        @click="toggleExpanded"
        class="text-sm px-4 py-2 bg-gradient-to-r from-blue-500 to-purple-500 text-white rounded-lg hover:from-blue-600 hover:to-purple-600 transition-all duration-300 shadow-md hover:shadow-lg transform hover:scale-105"
      >
        {{ isExpanded ? '收起' : '展開全部' }}
      </button>
    </div>

    <!-- Collapsed View: Show only latest step and progress bar -->
    <div v-if="!isExpanded" class="space-y-4">
      <!-- Empty State -->
      <div v-if="searchSteps.length === 0" class="text-center py-8">
        <div class="w-12 h-12 bg-gray-200 dark:bg-gray-700 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg class="w-6 h-6 text-gray-400 dark:text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
          </svg>
        </div>
        <p class="text-gray-500 dark:text-gray-400 text-sm">等待搜索開始...</p>
      </div>

      <!-- Latest Step -->
      <div v-if="latestStep" class="transform transition-all duration-500 ease-out">
        <div class="flex items-start space-x-4 p-4 rounded-xl" :class="{
          'bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-700': latestStep.status === 'processing',
          'bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-700': latestStep.status === 'completed',
          'bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700': latestStep.status === 'pending'
        }">
          <!-- Step Icon -->
          <div class="flex-shrink-0 mt-1">
            <div v-if="latestStep.status === 'processing'" class="w-5 h-5 bg-blue-500 rounded-full animate-pulse flex items-center justify-center">
              <div class="w-2 h-2 bg-white rounded-full animate-ping"></div>
            </div>
            <div v-else-if="latestStep.status === 'completed'" class="w-5 h-5 bg-green-500 rounded-full flex items-center justify-center">
              <svg class="w-3 h-3 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
              </svg>
            </div>
            <div v-else class="w-5 h-5 bg-gray-300 dark:bg-gray-600 rounded-full"></div>
          </div>
          
          <!-- Step Content -->
          <div class="flex-1 min-w-0">
            <div class="flex items-center space-x-2 mb-1">
              <h4 class="text-sm font-semibold" :class="{
                'text-blue-700 dark:text-blue-300': latestStep.status === 'processing',
                'text-green-700 dark:text-green-300': latestStep.status === 'completed',
                'text-gray-500 dark:text-gray-400': latestStep.status === 'pending'
              }">{{ latestStep.title }}</h4>
              <span v-if="latestStep.duration" class="text-xs text-gray-500 dark:text-gray-400">
                {{ latestStep.duration }}ms
              </span>
            </div>
            <p class="text-sm break-words overflow-wrap-anywhere" :class="{
              'text-blue-600 dark:text-blue-400': latestStep.status === 'processing',
              'text-green-600 dark:text-green-400': latestStep.status === 'completed',
              'text-gray-500 dark:text-gray-400': latestStep.status === 'pending'
            }">{{ latestStep.description }}</p>
          </div>
        </div>
      </div>

      <!-- Overall Progress Bar -->
      <div v-if="searchSteps.length > 0" class="mt-6">
        <div class="flex items-center justify-between mb-2">
          <span class="text-sm font-medium text-gray-700 dark:text-gray-300">整體進度</span>
          <span class="text-sm text-gray-500 dark:text-gray-400">{{ completedSteps }}/{{ totalSteps }}</span>
        </div>
        <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
          <div class="bg-gradient-to-r from-blue-500 to-purple-500 h-2 rounded-full transition-all duration-500" 
               :style="{ width: progressPercentage + '%' }"></div>
        </div>
      </div>
    </div>

    <!-- Expanded View: Show all steps -->
    <div v-else class="space-y-4 overflow-y-auto custom-scrollbar" :style="{ maxHeight: 'calc(100vh - 200px)' }">
      <div v-for="(step, index) in searchSteps" :key="index" class="p-4 bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 shadow-sm">
        <div class="flex items-start space-x-4">
          <!-- Step Number -->
          <div class="flex-shrink-0">
            <div class="w-8 h-8 rounded-full flex items-center justify-center text-sm font-semibold" :class="{
              'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300': step.status === 'processing',
              'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300': step.status === 'completed',
              'bg-gray-100 dark:bg-gray-700 text-gray-500 dark:text-gray-400': step.status === 'pending'
            }">
              {{ index + 1 }}
            </div>
          </div>
          
          <!-- Step Details -->
          <div class="flex-1 min-w-0">
            <div class="flex items-center justify-between mb-2">
              <h4 class="text-sm font-semibold text-gray-900 dark:text-gray-100">{{ step.title }}</h4>
              <div class="flex items-center space-x-2">
                <span v-if="step.duration" class="text-xs text-gray-500 dark:text-gray-400 bg-gray-100 dark:bg-gray-700 px-2 py-1 rounded">
                  {{ step.duration }}ms
                </span>
                <span class="text-xs px-2 py-1 rounded-full" :class="{
                  'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300': step.status === 'processing',
                  'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300': step.status === 'completed',
                  'bg-gray-100 dark:bg-gray-700 text-gray-500 dark:text-gray-400': step.status === 'pending'
                }">
                  {{ step.status === 'processing' ? '進行中' : step.status === 'completed' ? '已完成' : '等待中' }}
                </span>
              </div>
            </div>
            
            <p class="text-sm text-gray-600 dark:text-gray-400 mb-3 break-words overflow-wrap-anywhere">{{ step.description }}</p>
            
            <!-- Detailed Information -->
            <div v-if="step.details" class="space-y-2">
              <div v-if="step.details.method" class="text-xs">
                <span class="font-medium text-gray-700 dark:text-gray-300">搜索方法:</span>
                <span class="ml-2 bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-300 px-2 py-1 rounded">{{ step.details.method }}</span>
              </div>
              <div v-if="step.details.query" class="text-xs">
                <span class="font-medium text-gray-700 dark:text-gray-300">查詢內容:</span>
                <span class="ml-2 text-gray-600 dark:text-gray-400 font-mono bg-gray-50 dark:bg-gray-700 px-2 py-1 rounded">{{ step.details.query }}</span>
              </div>
              <div v-if="step.details.count !== undefined" class="text-xs">
                <span class="font-medium text-gray-700 dark:text-gray-300">結果數量:</span>
                <span class="ml-2 bg-green-50 dark:bg-green-900/20 text-green-700 dark:text-green-300 px-2 py-1 rounded">{{ step.details.count }} 筆</span>
              </div>
              <div v-if="step.details.error" class="text-xs">
                <span class="font-medium text-red-700 dark:text-red-300">錯誤信息:</span>
                <span class="ml-2 text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/20 px-2 py-1 rounded">{{ step.details.error }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Enhanced Connection Status -->
    <div v-if="connectionStatus" class="mt-6 flex items-center space-x-2">
      <div class="w-2 h-2 rounded-full" :class="connectionStatus.includes('已建立') ? 'bg-green-500 animate-pulse' : 'bg-red-500'"></div>
      <span class="text-xs text-gray-500 dark:text-gray-400">{{ connectionStatus }}</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';

interface SearchStep {
  id: string;
  title: string;
  description: string;
  status: 'pending' | 'processing' | 'completed' | 'error';
  startTime?: number;
  endTime?: number;
  duration?: number;
  details?: {
    method?: string;
    query?: string;
    count?: number;
    error?: string;
  };
}



const searchSteps = ref<SearchStep[]>([]);
const isExpanded = ref<boolean>(false);
const connectionStatus = ref<string>('未連接');

// Debug: Log when searchSteps changes
watch(searchSteps, (newSteps) => {
  console.log('Search steps updated:', newSteps);
}, { deep: true });

let socket: WebSocket | null = null;
let reconnectInterval: number | null = null;

const toggleExpanded = () => {
  isExpanded.value = !isExpanded.value;
};

// Computed properties for progress tracking
const completedSteps = computed(() => {
  return searchSteps.value.filter(step => step.status === 'completed').length;
});

const latestStep = computed(() => {
  if (searchSteps.value.length === 0) return null;
  const processingStep = searchSteps.value.find(step => step.status === 'processing');
  if (processingStep) return processingStep;
  for (let i = searchSteps.value.length - 1; i >= 0; i--) {
    if (searchSteps.value[i].status === 'completed') {
      return searchSteps.value[i];
    }
  }
  return searchSteps.value[0];
});

const totalSteps = computed(() => {
  return searchSteps.value.length;
});

const progressPercentage = computed(() => {
  if (totalSteps.value === 0) return 0;
  return Math.round((completedSteps.value / totalSteps.value) * 100);
});

// Initialize search steps
const initializeSearchSteps = (query: string) => {
  searchSteps.value = [
    {
      id: 'receive-query',
      title: '接收搜索請求',
      description: `正在處理查詢: "${query}"`,
      status: 'completed',
      details: { query }
    },
    {
      id: 'initialize-service',
      title: '初始化搜索服務',
      description: '連接資料庫並準備搜索引擎',
      status: 'pending'
    },
    {
      id: 'execute-search',
      title: '執行搜索',
      description: '使用混合搜索方法查詢相關案例',
      status: 'pending'
    },
    {
      id: 'process-results',
      title: '處理搜索結果',
      description: '去除重複項目並按相關性排序',
      status: 'pending'
    },
    {
      id: 'return-results',
      title: '返回結果',
      description: '格式化並返回最終搜索結果',
      status: 'pending'
    }
  ];
};

// Update step status
const updateStepStatus = (stepId: string, status: SearchStep['status'], details?: any) => {
  const step = searchSteps.value.find(s => s.id === stepId);
  if (step) {
    const now = Date.now();
    
    if (status === 'processing' && step.status === 'pending') {
      step.startTime = now;
    } else if ((status === 'completed' || status === 'error') && step.startTime) {
      step.endTime = now;
      step.duration = now - step.startTime;
    }
    
    step.status = status;
    if (details) {
      step.details = { ...step.details, ...details };
    }
  }
};

// Expose methods for parent component
const startSearch = (query: string) => {
  console.log('Starting search with query:', query);
  initializeSearchSteps(query);
  console.log('Search steps initialized:', searchSteps.value);
  updateStepStatus('initialize-service', 'processing');
};

const updateSearchProgress = (stepId: string, status: SearchStep['status'], details?: any) => {
  updateStepStatus(stepId, status, details);
};

// Expose methods to parent component
defineExpose({
  startSearch,
  updateSearchProgress
});

// WebSocket connection for real-time updates (optional enhancement)
const connect = () => {
  const apiUrl = import.meta.env.VITE_PYTHON_API_URL || 'http://localhost:8000';
  const wsUrl = apiUrl.replace(/^http/, 'ws');
  socket = new WebSocket(`${wsUrl}/ws/log`);

  socket.onmessage = (event) => {
    try {
      const message = JSON.parse(event.data);
      if (message.type === 'search_progress') {
        updateSearchProgress(message.step, message.status, message.details);
      }
    } catch (e) {
      // Handle non-JSON log messages if needed
      console.log('Received log message:', event.data);
    }
  };

  socket.onclose = () => {
    connectionStatus.value = '連接已斷開';
    // Attempt to reconnect after 3 seconds
    if (!reconnectInterval) {
      reconnectInterval = window.setInterval(() => {
        connect();
      }, 3000);
    }
  };

  socket.onerror = (error) => {
    console.error('WebSocket error:', error);
    connectionStatus.value = '連接錯誤';
  };

  socket.onopen = () => {
    connectionStatus.value = '連接已建立';
    if (reconnectInterval) {
      clearInterval(reconnectInterval);
      reconnectInterval = null;
    }
  };
};

onMounted(() => {
  connect();
});

onUnmounted(() => {
  if (socket) {
    socket.close();
  }
  if (reconnectInterval) {
    clearInterval(reconnectInterval);
  }
});
</script>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
}

.custom-scrollbar::-webkit-scrollbar-track {
  background: #f1f5f9;
  border-radius: 3px;
}

.custom-scrollbar::-webkit-scrollbar-thumb {
  background: linear-gradient(to bottom, #3b82f6, #8b5cf6);
  border-radius: 3px;
}

.custom-scrollbar::-webkit-scrollbar-thumb:hover {
  background: linear-gradient(to bottom, #2563eb, #7c3aed);
}

.dark .custom-scrollbar::-webkit-scrollbar-track {
  background: #374151;
}
</style>


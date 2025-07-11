<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useWorkspaceStore } from '../store/workspace';
import SearchModule from '../components/SearchModule.vue';
import FormInput from '../components/FormInput.vue';
import LogDisplay from '../components/LogDisplay.vue';

const workspaceStore = useWorkspaceStore();
const activeTab = ref<'search' | 'generate'>('search');
const refinementSteps = ref<any[]>([]);
const logDisplayRef = ref<InstanceType<typeof LogDisplay> | null>(null);
const generateModuleRef = ref<InstanceType<typeof FormInput> | null>(null);
const searchModuleRef = ref<InstanceType<typeof SearchModule> | null>(null);

// Handle cases selection change from search module
const handleCasesSelectionChanged = () => {
  // Notify GenerateModule to reload selected cases
  if (generateModuleRef.value && typeof generateModuleRef.value.loadSelectedCases === 'function') {
    generateModuleRef.value.loadSelectedCases();
  }
  
  // Notify SearchModule to reload search state to update UI
  if (searchModuleRef.value && typeof searchModuleRef.value.loadSearchState === 'function') {
    searchModuleRef.value.loadSearchState();
  }
};
const isChatExpanded = ref(false);

const toggleChat = () => {
  isChatExpanded.value = !isChatExpanded.value;
};

// 機器人圖示動畫
const isRobotAnimating = ref(false);

const animateRobot = () => {
  isRobotAnimating.value = true;
  setTimeout(() => {
    isRobotAnimating.value = false;
  }, 600); // 動畫持續600ms
};

// 每3秒觸發一次動畫
setInterval(animateRobot, 3000);

// Handle refinement steps from SearchModule
const handleRefinementSteps = (steps: any[]) => {
  refinementSteps.value = steps;
};

// Handle search progress events
const handleSearchProgress = (event: any) => {
  if (logDisplayRef.value) {
    if (event.event === 'startSearch') {
      logDisplayRef.value.startSearch(event.query);
    } else if (event.event === 'updateSearchProgress') {
      logDisplayRef.value.updateSearchProgress(event.stepId, event.status, event.details);
    }
  }
};

onMounted(async () => {
  // Load workspaces from database
  await workspaceStore.loadWorkspaces();
  
  // If no workspaces exist, create one
  if (workspaceStore.workspaces.length === 0) {
    await workspaceStore.addWorkspace();
  }
  
  // Only load latest search results if there are no existing results to preserve UI state
  if (workspaceStore.activeWorkspaceId && !workspaceStore.activeTask?.latestSearchResult) {
    await workspaceStore.loadLatestSearchResult(workspaceStore.activeWorkspaceId);
  }
});
</script>

<template>
  <div class="p-8 h-full">
    <div class="flex flex-col">
    <!-- Loading State -->
    <div v-if="workspaceStore.isLoading" class="flex items-center justify-center h-64">
      <div class="text-center">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-2"></div>
        <p class="text-gray-500 dark:text-gray-300">載入工作區中...</p>
      </div>
    </div>

    <!-- Error State -->
    <div v-else-if="workspaceStore.error" class="p-4 bg-red-50 dark:bg-gray-800 border border-red-200 dark:border-black rounded-lg mb-6">
      <p class="text-red-600 dark:text-gray-200">{{ workspaceStore.error }}</p>
    </div>

    <!-- Main Content -->
    <div v-else-if="workspaceStore.activeWorkspace" class="h-full flex flex-col">
      <!-- Header -->
      <h1 class="text-2xl font-bold mb-1 text-blue-700 dark:text-white">
        {{ workspaceStore.activeWorkspace.name }}
      </h1>
      <p class="text-sm text-gray-500 dark:text-gray-300 mb-6">
        任務 ID: {{ workspaceStore.activeWorkspace.id }}...
      </p>

    <!-- Tab Navigation -->
    <div class="border-b border-gray-300 dark:border-black mb-6">
      <nav class="relative -mb-px flex gap-6">
        <!-- Animated underline indicator -->
        <div 
          class="absolute bottom-0 h-0.5 bg-gradient-to-r from-blue-600 to-blue-700 transition-all duration-300 ease-out"
          :style="{
            left: activeTab === 'search' ? '0px' : '60px',
            width: '36px'
          }"
        ></div>
        <button
          ref="searchTab"
          @click="activeTab = 'search'"
          :class="['relative py-2 px-1 text-sm font-medium transition-colors duration-200', activeTab === 'search' ? 'text-blue-700 dark:text-white' : 'text-gray-500 dark:text-gray-300 hover:text-gray-700 dark:hover:text-white']">
          搜尋
        </button>
        <button
          ref="generateTab"
          @click="activeTab = 'generate'"
          :class="['relative py-2 px-1 text-sm font-medium transition-colors duration-200', activeTab === 'generate' ? 'text-blue-600 dark:text-white' : 'text-gray-500 dark:text-gray-300 hover:text-gray-700 dark:hover:text-white']">
          輸入
        </button>
      </nav>
    </div>

      <!-- Tab Content -->
      <div class="flex-1 flex gap-6">
        <!-- Main Content Area -->
        <div class="flex-1 overflow-y-auto">
          <div v-show="activeTab === 'search'" class="space-y-6">
            <SearchModule ref="searchModuleRef" @update:search-progress="handleSearchProgress" @cases-selection-changed="handleCasesSelectionChanged" />
          </div>
          <div v-show="activeTab === 'generate'" class="space-y-6">
            <FormInput ref="generateModuleRef" @refinement-steps="handleRefinementSteps" @cases-selection-changed="handleCasesSelectionChanged" />
          </div>
        </div>
        
        <!-- Log Display Sidebar - Only show on search tab -->
        <div v-show="activeTab === 'search'" class="w-1/3 min-w-0">
          <LogDisplay ref="logDisplayRef" :refinement-steps="refinementSteps" />
        </div>
      </div>
    </div>

    <!-- No Workspace State -->
    <div v-else class="flex items-center justify-center h-64">
      <div class="text-center">
        <p class="text-gray-500 dark:text-gray-300 mb-4">沒有可用的工作區</p>
        <button
          @click="workspaceStore.addWorkspace"
          class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-md transition-colors"
        >
          建立新工作區
        </button>
      </div>
    </div>
    

    
    <!-- Floating Chat Widget -->
    <div class="fixed bottom-6 right-16 z-50">
      <!-- Collapsed Chat Button -->
      <div v-if="!isChatExpanded" 
           @click="toggleChat"
           class="relative bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white rounded-full p-4 shadow-lg cursor-pointer transition-all duration-300 hover:scale-105 flex items-center gap-3">
        <!-- Wave Animation Background -->
        <div v-if="isRobotAnimating" class="absolute inset-0 rounded-full">
          <div class="absolute inset-0 rounded-full bg-blue-400 opacity-30 animate-ping"></div>
          <div class="absolute inset-0 rounded-full bg-blue-300 opacity-20 animate-ping" style="animation-delay: 0.2s;"></div>
          <div class="absolute inset-0 rounded-full bg-blue-200 opacity-10 animate-ping" style="animation-delay: 0.4s;"></div>
        </div>
        <img src="/rob.svg" alt="Robot" 
             :class="['w-6 h-6 transition-transform duration-300 relative z-10', isRobotAnimating ? 'animate-bounce' : '']" />
        <span class="text-sm font-medium relative z-10">呼叫老外</span>
      </div>
      
      <!-- Expanded Chat Window -->
      <div v-else class="bg-white dark:bg-gray-900 rounded-lg shadow-xl border border-gray-200 dark:border-black w-96 h-96 flex flex-col">
        <!-- Chat Header -->
        <div class="bg-blue-600 text-white p-4 rounded-t-lg flex items-center justify-between">
          <div class="flex items-center gap-2">
            <img src="/rob.svg" alt="Robot" class="w-5 h-5" />
            <span class="font-medium">AI 助手</span>
          </div>
          <button @click="toggleChat" class="text-white hover:text-gray-200 transition-colors">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>
        
        <!-- Chat Content -->
        <div class="flex-1 p-4 overflow-y-auto">
          <div class="text-center text-gray-500 dark:text-gray-300 text-sm">
            對話功能開發中...
          </div>
        </div>
        
        <!-- Chat Input -->
        <div class="p-4 border-t border-gray-200 dark:border-black">
          <div class="flex gap-2">
            <input type="text" placeholder="輸入訊息..." 
                   class="flex-1 px-3 py-2 border border-gray-300 dark:border-black rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-800 dark:text-white" 
                   disabled />
            <button class="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm hover:bg-blue-700 transition-colors" disabled>
              發送
            </button>
          </div>
        </div>
      </div>
    </div>
    </div>
  </div>
</template>
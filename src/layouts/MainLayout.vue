<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { useWorkspaceStore } from '../store/workspace';
import { useAuthStore } from '../store/auth';
import { LogOut, PlusSquare, Edit2, Check, X, Trash2, User, ChevronDown } from 'lucide-vue-next';
import ThemeToggle from '../components/ThemeToggle.vue';


const workspaceStore = useWorkspaceStore();
const authStore = useAuthStore();
const router = useRouter();

const editingWorkspaceId = ref<string | null>(null);
const editingName = ref('');
const showUserMenu = ref(false);

// Reactive theme detection for logo
const isDarkMode = ref(false);

// Function to update theme state
const updateTheme = () => {
  isDarkMode.value = document.documentElement.classList.contains('dark');
};

// Computed property for theme-appropriate logo
const logoImage = computed(() => {
  return isDarkMode.value ? '/lawai_white.svg' : '/lawai_black.svg';
});

// Handles the logout process
async function handleLogout() {
  try {
    await authStore.logout();
    // After logout, redirect user to the login page
    router.push({ name: 'login' });
  } catch (error) {
    console.error('Logout error:', error);
    // Even if logout fails, redirect to login page
    router.push({ name: 'login' });
  }
}

// Handle workspace switching with search results loading
async function handleWorkspaceSwitch(workspaceId: string) {
  workspaceStore.switchWorkspace(workspaceId);
  
  // Only load search results if the workspace doesn't have existing results to preserve UI state
  if (!workspaceStore.activeTask?.latestSearchHistory) {
    const searchResults = await workspaceStore.loadSearchResults(workspaceId);
    if (searchResults && workspaceStore.activeWorkspace) {
      workspaceStore.activeWorkspace.searchResults = searchResults.results;
    }
  }
}

// Start editing workspace name
function startEditingName(workspace: any) {
  editingWorkspaceId.value = workspace.id;
  editingName.value = workspace.name;
}

// Save workspace name
async function saveWorkspaceName() {
  if (editingWorkspaceId.value && editingName.value.trim()) {
    await workspaceStore.updateWorkspaceName(editingWorkspaceId.value, editingName.value.trim());
  }
  editingWorkspaceId.value = null;
  editingName.value = '';
}

// Cancel editing
function cancelEditing() {
  editingWorkspaceId.value = null;
  editingName.value = '';
}

// Delete workspace with confirmation
function deleteWorkspace(workspace: any) {
  if (workspaceStore.workspaces.length <= 1) {
    alert('無法刪除最後一個工作區');
    return;
  }
  
  if (confirm(`確定要刪除工作區「${workspace.name}」嗎？此操作無法復原。`)) {
    workspaceStore.deleteWorkspace(workspace.id);
  }
}

// Toggle user menu
function toggleUserMenu() {
  showUserMenu.value = !showUserMenu.value;
}

// Handle user center (placeholder)
function handleUserCenter() {
  showUserMenu.value = false;
  // TODO: 實作使用者中心邏輯
  console.log('使用者中心功能待實作');
}

// Handle logout with menu close
function handleLogoutFromMenu() {
  showUserMenu.value = false;
  handleLogout();
}

// Close menu when clicking outside
function handleClickOutside(event: Event) {
  const target = event.target as Element;
  if (!target.closest('.user-menu-container')) {
    showUserMenu.value = false;
  }
}

// Add event listener for clicking outside
onMounted(() => {
  document.addEventListener('click', handleClickOutside);
  
  // Initialize theme state
  updateTheme();
  
  // Watch for theme changes using MutationObserver
  const observer = new MutationObserver(() => {
    updateTheme();
  });
  
  observer.observe(document.documentElement, {
    attributes: true,
    attributeFilter: ['class']
  });
  
  // Store observer reference for cleanup
  (window as any).__logoThemeObserver = observer;
});

// Remove event listener on unmount
onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside);
  
  // Clean up theme observer
  const observer = (window as any).__logoThemeObserver;
  if (observer) {
    observer.disconnect();
    delete (window as any).__logoThemeObserver;
  }
});
</script>

<template>
  <div class="flex h-screen w-full bg-gray-100 dark:bg-black text-gray-800 dark:text-white">
    <!-- Sidebar -->
    <aside class="w-64 flex-shrink-0 bg-white dark:bg-gray-900 flex flex-col p-4 border-r border-gray-200 dark:border-0 relative">
      <!-- Logo and Theme Toggle -->
      <div class="flex items-center justify-between mb-8">
        <img :src="logoImage" alt="Lawai Logo" class="h-10 transition-opacity duration-300" />
        <ThemeToggle />
      </div>

      <!-- Workspace List -->
      <nav class="flex-grow overflow-y-auto pb-28">
        <h2 class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">工作區</h2>
        <ul>
          <li
            v-for="ws in workspaceStore.workspaces"
            :key="ws.id"
            class="mb-1 text-sm transition-colors"
          >
            <div
              v-if="editingWorkspaceId !== ws.id"
              @click="handleWorkspaceSwitch(ws.id)"
              class="p-2 rounded-md cursor-pointer flex items-center justify-between group"
              :class="{
                'bg-gradient-to-r from-cyan-500 to-blue-600 text-white font-semibold': ws.id === workspaceStore.activeWorkspaceId,
                'hover:bg-gray-200 dark:hover:bg-gray-800': ws.id !== workspaceStore.activeWorkspaceId
              }"
            >
              <span class="truncate">{{ ws.name }}</span>
              <div class="flex items-center gap-1">
                <button
                  @click.stop="startEditingName(ws)"
                  class="opacity-0 group-hover:opacity-100 p-1 rounded hover:bg-gray-300 dark:hover:bg-gray-700 transition-opacity"
                  :class="{
                    'hover:bg-blue-700': ws.id === workspaceStore.activeWorkspaceId
                  }"
                  title="編輯工作區名稱"
                >
                  <Edit2 class="w-3 h-3" />
                </button>
                <button
                  @click.stop="deleteWorkspace(ws)"
                  class="opacity-0 group-hover:opacity-100 p-1 rounded hover:bg-red-500 hover:text-white transition-all"
                  :class="{
                    'hover:bg-red-600': ws.id === workspaceStore.activeWorkspaceId
                  }"
                  title="刪除工作區"
                >
                  <Trash2 class="w-3 h-3" />
                </button>
              </div>
            </div>
            
            <!-- Editing mode -->
            <div v-else class="p-2 rounded-md bg-gray-100 dark:bg-gray-800 flex items-center gap-1">
              <input
                v-model="editingName"
                @keyup.enter="saveWorkspaceName"
                @keyup.escape="cancelEditing"
                class="flex-1 px-2 py-1 text-xs rounded border border-gray-300 dark:border-gray-500 bg-white dark:bg-gray-900 focus:outline-none focus:ring-1 focus:ring-blue-500"
                autofocus
              />
              <button
                @click="saveWorkspaceName"
                class="p-1 rounded text-green-600 hover:bg-green-100 dark:hover:bg-green-900"
              >
                <Check class="w-3 h-3" />
              </button>
              <button
                @click="cancelEditing"
                class="p-1 rounded text-red-600 hover:bg-red-100 dark:hover:bg-red-900"
              >
                <X class="w-3 h-3" />
              </button>
            </div>
          </li>
        </ul>
        <button
          @click="workspaceStore.addWorkspace"
          class="w-full mt-2 p-2 flex items-center justify-center text-sm rounded-md hover:bg-gray-200 dark:hover:bg-gray-800 transition-colors"
        >
          <PlusSquare class="w-4 h-4 mr-2" />
          新增任務
        </button>
      </nav>

      <!-- User Info & Controls section -->
      <div class="absolute bottom-0 left-0 right-0 p-4 bg-white dark:bg-gray-900 border-t border-gray-200 dark:border-gray-600 relative">
        <!-- User Info with Dropdown -->
         <div class="relative user-menu-container">
          <button @click="toggleUserMenu" class="w-full flex items-center gap-3 p-2 rounded-md hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors">
            <div class="w-8 h-8 rounded-full bg-gradient-to-r from-cyan-500 to-blue-600 flex items-center justify-center text-white font-semibold text-xs flex-shrink-0">
              {{ authStore.user?.email?.charAt(0).toUpperCase() || 'U' }}
            </div>
            <div class="flex-1 min-w-0 text-left">
              <div class="text-sm font-medium text-gray-900 dark:text-white truncate">
                {{ authStore.user?.email || '訪客用戶' }}
              </div>
              <div class="text-xs text-gray-500 dark:text-gray-300">
                {{ authStore.isAuthenticated ? '已登入' : '未登入' }}
              </div>
            </div>
            <div class="flex items-center gap-2">
              <div class="w-2.5 h-2.5 rounded-full bg-green-500 flex-shrink-0"></div>
              <ChevronDown class="w-4 h-4 text-gray-400 transition-transform" :class="{ 'rotate-180': showUserMenu }" />
            </div>
          </button>
          
          <!-- Dropdown Menu -->
          <div v-if="showUserMenu" class="absolute bottom-full left-0 right-0 mb-2 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-600 rounded-md shadow-lg py-1">
            <button @click="handleUserCenter" class="w-full px-4 py-2 text-left text-sm text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 flex items-center gap-2">
              <User class="w-4 h-4" />
              <span>使用者中心</span>
            </button>
            <button @click="handleLogoutFromMenu" class="w-full px-4 py-2 text-left text-sm text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 flex items-center gap-2">
              <LogOut class="w-4 h-4" />
              <span>登出</span>
            </button>
          </div>
        </div>
      </div>
    </aside>

    <!-- Main Content -->
    <main class="flex-1 overflow-y-auto">
      <!-- The router will render the correct child component (e.g., WorkspaceView) here -->
      <router-view />
    </main>
  </div>
</template>
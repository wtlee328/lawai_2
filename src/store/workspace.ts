import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '../supabase'
import { useAuthStore } from './auth'

// Define the structure of a search result
export interface SearchResult {
  id: string;
  task_id: string;
  user_id: string;
  query_text: any; // JSONB format: {query: string} for general, {content: string, dispute: string, etc.} for multi-field
  search_mode: string; // 'general' or 'multi_field'
  results: any;
  case_ids: string[];
  search_count: number;
  created_at: string;
  last_searched_at: string;
  added_to_doc_gen?: any;
}

// Define the structure of a single task (formerly workspace)
export interface Task {
  id: string; // Changed to string for UUID
  user_id: string;
  name: string;
  status: 'active' | 'deleted';
  created_at: string;
  searchResults?: any | null; // This field holds the search results (optional for local state)
  currentQuery?: string; // Current query text in search input
  latestSearchHistory?: SearchResult[] | null; // Latest search results from database
}

// Keep Workspace as an alias for backward compatibility
export type Workspace = Task;

export const useWorkspaceStore = defineStore('workspace', () => {
  // --- STATE ---
  const tasks = ref<Task[]>([]);
  const activeTaskId = ref<string | null>(null);
  const isLoading = ref(false);
  const error = ref<string | null>(null);

  // --- GETTERS ---
  const activeTask = computed(() => {
    return tasks.value.find(task => task.id === activeTaskId.value);
  });

  // Backward compatibility getters
  const workspaces = computed(() => tasks.value);
  const activeWorkspaceId = computed(() => activeTaskId.value);
  const activeWorkspace = computed(() => activeTask.value);

  // --- ACTIONS ---
  async function loadTasks() {
    const authStore = useAuthStore();
    if (!authStore.user) return;

    isLoading.value = true;
    error.value = null;

    try {
      const { data: _data, error: supabaseError } = await supabase
        .from('tasks')
        .select('*')
        .eq('user_id', authStore.user.id)
        .eq('status', 'active')
        .order('created_at', { ascending: false });

      if (supabaseError) throw supabaseError;

      tasks.value = _data || [];
      
      // Set first task as active if none selected
      if (tasks.value.length > 0 && !activeTaskId.value) {
        activeTaskId.value = tasks.value[0].id;
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to load tasks';
      console.error('Error loading tasks:', err);
    } finally {
      isLoading.value = false;
    }
  }

  // Backward compatibility function
  const loadWorkspaces = loadTasks;

  async function addTask() {
    const authStore = useAuthStore();
    if (!authStore.user) {
      error.value = 'User not authenticated';
      return;
    }

    if (tasks.value.length >= 5) {
      alert("您已達到最多 5 個任務的限制。");
      return;
    }

    isLoading.value = true;
    error.value = null;

    try {
      const { data, error: supabaseError } = await supabase
        .from('tasks')
        .insert({
          user_id: authStore.user.id,
          name: '新任務',
          status: 'active'
        })
        .select()
        .single();

      if (supabaseError) throw supabaseError;

      tasks.value.unshift(data);
      switchTask(data.id);
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to create task';
      console.error('Error creating task:', err);
    } finally {
      isLoading.value = false;
    }
  }

  // Backward compatibility function
  const addWorkspace = addTask;

  function switchTask(id: string) {
    activeTaskId.value = id;
  }

  // Backward compatibility function
  const switchWorkspace = switchTask;

  async function updateTaskName(id: string, newName: string) {
    const authStore = useAuthStore();
    if (!authStore.user) return;

    isLoading.value = true;
    error.value = null;

    try {
      const { error: supabaseError } = await supabase
        .from('tasks')
        .update({ name: newName })
        .eq('id', id)
        .eq('user_id', authStore.user.id);

      if (supabaseError) throw supabaseError;

      // Update local state
      const task = tasks.value.find(t => t.id === id);
      if (task) {
        task.name = newName;
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to update task name';
      console.error('Error updating task name:', err);
    } finally {
      isLoading.value = false;
    }
  }

  // Backward compatibility function
  const updateWorkspaceName = updateTaskName;

  // Save search results to database with case_ids and search_mode
  async function saveSearchResults(queryText: string | object, results: any, caseIds: string[] = [], addedToDocGen: any = null, searchMode: string = 'general') {
    const authStore = useAuthStore();
    if (!authStore.user || !activeTaskId.value) return;

    try {
      // Convert queryText to proper JSONB format
      let queryTextJsonb;
      if (typeof queryText === 'string') {
        queryTextJsonb = { query: queryText };
      } else {
        queryTextJsonb = queryText;
      }

      // Use the upsert function to handle duplicate queries
      const { data: _data, error: supabaseError } = await supabase
        .rpc('upsert_search_result_v2', {
          p_task_id: activeTaskId.value,
          p_user_id: authStore.user.id,
          p_query_text: queryTextJsonb,
          p_search_mode: searchMode,
          p_results: results,
          p_case_ids: caseIds,
          p_added_to_doc_gen: addedToDocGen
        });

      if (supabaseError) throw supabaseError;

      // Update local state for immediate UI feedback
      if (activeTask.value) {
        activeTask.value.searchResults = results;
        // Load the latest search result to update the state
        await loadSearchHistory(activeTaskId.value);
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to save search results';
      console.error('Error saving search results:', err);
    }
  }

  // Load search results for a task (backward compatibility)
  async function loadSearchResults(taskId: string) {
    const authStore = useAuthStore();
    if (!authStore.user) return null;

    try {
      const { data, error: supabaseError } = await supabase
        .from('search_results')
        .select('*')
        .eq('task_id', taskId)
        .eq('user_id', authStore.user.id)
        .order('last_searched_at', { ascending: false })
        .limit(1)
        .single();

      if (supabaseError && supabaseError.code !== 'PGRST116') { // PGRST116 = no rows returned
        throw supabaseError;
      }

      return data;
    } catch (err) {
      console.error('Error loading search results:', err);
      return null;
    }
  }

  // Load search history for a task and update local state
  async function loadSearchHistory(taskId: string) {
    const authStore = useAuthStore();
    if (!authStore.user) return null;

    try {
      const { data, error: supabaseError } = await supabase
        .from('search_results')
        .select('*')
        .eq('task_id', taskId)
        .order('created_at', { ascending: false })
        .limit(5);

      if (supabaseError) throw supabaseError;

      const task = tasks.value.find(t => t.id === taskId);
      if (task && data) {
        const searchHistory = data as SearchResult[];
        
        task.latestSearchHistory = searchHistory;
        task.searchResults = searchHistory.length > 0 ? searchHistory[0].results : null;
        // Don't override currentQuery if user is typing
        if (!task.currentQuery) {
          task.currentQuery = searchHistory.length > 0 ? searchHistory[0].query_text : '';
        }
      }

      return data;
    } catch (err) {
      console.error('Error loading search history:', err);
      return null;
    }
  }

  // Update current query text for a task (for input persistence)
  function updateCurrentQuery(taskId: string, queryText: string) {
    const task = tasks.value.find(t => t.id === taskId);
    if (task) {
      task.currentQuery = queryText;
    }
  }

  // Get current query text for a task
  function getCurrentQuery(taskId: string): string {
    const task = tasks.value.find(t => t.id === taskId);
    return task?.currentQuery || (task?.latestSearchHistory && task.latestSearchHistory.length > 0 ? task.latestSearchHistory[0].query_text : '');
  }

  // Clear current query (on logout)
  function clearCurrentQueries() {
    tasks.value.forEach(task => {
      task.currentQuery = undefined;
    });
  }

  // Delete task (soft delete)
  async function deleteTask(id: string) {
    const authStore = useAuthStore();
    if (!authStore.user) return;

    isLoading.value = true;
    error.value = null;

    try {
      const { error: supabaseError } = await supabase
        .from('tasks')
        .update({ status: 'deleted' })
        .eq('id', id)
        .eq('user_id', authStore.user.id);

      if (supabaseError) throw supabaseError;

      // Remove from local state
      tasks.value = tasks.value.filter(t => t.id !== id);
      
      // If deleted task was active, switch to another one
      if (activeTaskId.value === id) {
        if (tasks.value.length > 0) {
          switchTask(tasks.value[0].id);
        } else {
          activeTaskId.value = null;
        }
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to delete task';
      console.error('Error deleting task:', err);
    } finally {
      isLoading.value = false;
    }
  }

  // Backward compatibility function
  const deleteWorkspace = deleteTask;

  // Get selected cases for document generation
  async function getSelectedCases() {
    if (!activeTaskId.value) return [];
    
    try {
      const { data, error: supabaseError } = await supabase
        .from('search_results')
        .select('*')
        .eq('task_id', activeTaskId.value)
        .order('created_at', { ascending: false })
        .limit(5);

      if (supabaseError) throw supabaseError;
      
      if (data && data.length > 0) {
        const selectedCasesMap = new Map();

        data.forEach(searchResult => {
          const results = searchResult.results || [];
          results.forEach((result: any) => {
            const addedToDocGen = searchResult.added_to_doc_gen?.[result.case_id];
            if (addedToDocGen === 'y') {
              selectedCasesMap.set(result.case_id, {
                case_id: result.case_id,
                title: result.case_id,
                court: result.court,
                date: result.date_decided,
                summary: result.summary,
                relevance_score: result.relevance_score
              });
            }
          });
        });
        
        return Array.from(selectedCasesMap.values());
      }
      
      return [];
    } catch (err) {
      console.error('Error getting selected cases:', err);
      return [];
    }
  }

  return {
    // New task-based API
    tasks,
    activeTaskId,
    activeTask,
    loadTasks,
    addTask,
    switchTask,
    updateTaskName,
    deleteTask,
    
    // Backward compatibility (workspace-based API)
    workspaces,
    activeWorkspaceId,
    activeWorkspace,
    loadWorkspaces,
    addWorkspace,
    switchWorkspace,
    updateWorkspaceName,
    deleteWorkspace,
    
    // Common functions
    isLoading,
    error,
    saveSearchResults,
    loadSearchResults,
    loadSearchHistory,
    updateCurrentQuery,
    getCurrentQuery,
    clearCurrentQueries,
    getSelectedCases
  }
});
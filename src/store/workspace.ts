import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '../supabase'
import { useAuthStore } from './auth'

// Define the structure of a search result
export interface SearchResult {
  id: string;
  task_id: string;
  user_id: string;
  query_text: string;
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
  latestSearchResult?: SearchResult | null; // Latest search result from database
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

  // Save search results to database with case_ids
  async function saveSearchResults(queryText: string, results: any, caseIds: string[] = [], addedToDocGen: any = null) {
    const authStore = useAuthStore();
    if (!authStore.user || !activeTaskId.value) return;

    try {
      // Use the upsert function to handle duplicate queries
      const { data: _data, error: supabaseError } = await supabase
        .rpc('upsert_search_result', {
          p_task_id: activeTaskId.value,
          p_user_id: authStore.user.id,
          p_query_text: queryText,
          p_results: results,
          p_case_ids: caseIds,
          p_added_to_doc_gen: addedToDocGen
        });

      if (supabaseError) throw supabaseError;

      // Update local state for immediate UI feedback
      if (activeTask.value) {
        activeTask.value.searchResults = results;
        // Load the latest search result to update the state
        await loadLatestSearchResult(activeTaskId.value);
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

  // Load latest search result for a task and update local state
  async function loadLatestSearchResult(taskId: string) {
    const authStore = useAuthStore();
    if (!authStore.user) return null;

    try {
      const { data, error: supabaseError } = await supabase
        .rpc('get_latest_search_result', { task_uuid: taskId });

      if (supabaseError) throw supabaseError;

      const task = tasks.value.find(t => t.id === taskId);
      if (task && data && data.length > 0) {
        const latestResult = data[0] as SearchResult;
        
        task.latestSearchResult = latestResult;
        task.searchResults = latestResult.results;
        // Don't override currentQuery if user is typing
        if (!task.currentQuery) {
          task.currentQuery = latestResult.query_text;
        }
      }

      return data && data.length > 0 ? data[0] : null;
    } catch (err) {
      console.error('Error loading latest search result:', err);
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
    return task?.currentQuery || task?.latestSearchResult?.query_text || '';
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
        .order('last_searched_at', { ascending: false })
        .limit(1);

      if (supabaseError) throw supabaseError;
      
      if (data && data.length > 0) {
        const searchResult = data[0];
        const results = searchResult.results || [];
        
        // Filter results where added_to_doc_gen is 'y'
        const selectedCases = results.filter((result: any) => {
          const addedToDocGen = searchResult.added_to_doc_gen?.[result.case_id];
          return addedToDocGen === 'y';
        }).map((result: any) => ({
          case_id: result.case_id,
          title: result.title || result.case_number,
          court: result.court,
          date: result.date_decided,
          summary: result.summary,
          relevance_score: result.relevance_score
        }));
        
        return selectedCases;
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
    loadLatestSearchResult,
    updateCurrentQuery,
    getCurrentQuery,
    clearCurrentQueries,
    getSelectedCases
  }
});
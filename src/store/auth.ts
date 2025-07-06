import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '../supabase'
import type { User, AuthError } from '@supabase/supabase-js'

export const useAuthStore = defineStore('auth', () => {
  // --- STATE ---
  const user = ref<User | null>(null);
  const error = ref<AuthError | null>(null);
  const isLoading = ref(false);

  // --- GETTERS ---
  const isAuthenticated = computed(() => !!user.value);

  // --- ACTIONS ---
  
  // Initialize the session from Supabase
  async function initSession() {
    const { data } = await supabase.auth.getSession();
    user.value = data.session?.user ?? null;
  }

  // Handle user login with email
  async function login(email: string, password: string) {
    isLoading.value = true;
    error.value = null;
    const { data, error: authError } = await supabase.auth.signInWithPassword({ email, password });
    if (authError) {
      error.value = authError;
      user.value = null;
    } else {
      user.value = data.user;
    }
    isLoading.value = false;
  }

  // Handle user signup with email
  async function signup(email: string, password: string) {
    isLoading.value = true;
    error.value = null;
    const { data, error: authError } = await supabase.auth.signUp({ email, password });
    if (authError) {
      error.value = authError;
    } else if (data.user) {
      user.value = data.user;
      // You can add logic here to handle email confirmation if enabled
    }
    isLoading.value = false;
  }

  // Handle user logout
  async function logout() {
    await supabase.auth.signOut();
    user.value = null;
    
    // Clear current queries from workspace store
    const { useWorkspaceStore } = await import('./workspace');
    const workspaceStore = useWorkspaceStore();
    workspaceStore.clearCurrentQueries();
  }

  return {
    user,
    error,
    isLoading,
    isAuthenticated,
    initSession,
    login,
    signup,
    logout
  }
});
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
    
    // Listen for auth state changes
    supabase.auth.onAuthStateChange((_, session) => {
      user.value = session?.user ?? null;
      error.value = null;
    });
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

  // Handle Google OAuth login
  async function loginWithGoogle() {
    isLoading.value = true;
    error.value = null;
    const { error: authError } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `${window.location.origin}/workspace`
      }
    });
    if (authError) {
      error.value = authError;
    }
    isLoading.value = false;
  }

  // Handle user logout
  async function logout() {
    try {
      // Always attempt to sign out to clear all session data
      const { error } = await supabase.auth.signOut();
      if (error && error.message !== 'Auth session missing!') {
        console.warn('Supabase signOut error:', error.message);
      }
    } catch (error) {
      console.warn('SignOut API call failed:', error);
    } finally {
      // Force clear local state and localStorage
      user.value = null;
      
      // Clear localStorage manually to ensure complete logout
      try {
        // Clear common Supabase auth keys
        const keys = Object.keys(localStorage);
        keys.forEach(key => {
          if (key.includes('supabase') || key.includes('sb-')) {
            localStorage.removeItem(key);
          }
        });
      } catch (error) {
        console.warn('Error clearing localStorage:', error);
      }
      
      // Clear current queries from workspace store
      try {
        const { useWorkspaceStore } = await import('./workspace');
        const workspaceStore = useWorkspaceStore();
        workspaceStore.clearCurrentQueries();
      } catch (error) {
        console.warn('Error clearing workspace queries:', error);
      }
    }
  }

  return {
    user,
    error,
    isLoading,
    isAuthenticated,
    initSession,
    login,
    signup,
    loginWithGoogle,
    logout
  }
});
<script setup lang="ts">
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '../store/auth';

const authStore = useAuthStore();
const router = useRouter();

const email = ref('');
const password = ref('');

const handleLogin = async () => {
  await authStore.login(email.value, password.value);
  if (authStore.isAuthenticated) {
    router.push({ name: 'workspace' });
  }
};

const handleSignup = async () => {
  await authStore.signup(email.value, password.value);
  if (authStore.isAuthenticated) {
    // Note: Supabase may require email verification. For local dev, auto-login is fine.
    alert('註冊成功！請登入。');
  }
};
</script>

<template>
  <div class="flex h-screen items-center justify-center bg-gray-100 dark:bg-black">
    <div class="w-full max-w-md rounded-lg bg-white p-8 shadow-lg dark:bg-gray-900">
      <h2 class="text-2xl font-bold text-center text-gray-800 dark:text-white">Lawai 登入</h2>
      
      <div class="mt-6">
        <label for="email" class="block text-sm font-medium text-gray-700 dark:text-gray-200">電子郵件地址</label>
        <input v-model="email" id="email" type="email" required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-500 dark:text-white">
      </div>
      
      <div class="mt-4">
        <label for="password" class="block text-sm font-medium text-gray-700 dark:text-gray-200">密碼</label>
        <input v-model="password" id="password" type="password" required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-500 dark:text-white">
      </div>

      <div v-if="authStore.error" class="mt-4 text-sm text-red-600 dark:text-gray-200">
        {{ authStore.error.message }}
      </div>

      <div class="mt-6 flex items-center justify-between gap-4">
        <button @click="handleLogin" :disabled="authStore.isLoading" class="w-full rounded-md bg-blue-600 py-2 text-white hover:bg-blue-700 disabled:bg-gray-500">
          {{ authStore.isLoading ? '...' : '登入' }}
        </button>
        <button @click="handleSignup" :disabled="authStore.isLoading" class="w-full rounded-md bg-green-600 py-2 text-white hover:bg-green-700 disabled:bg-gray-500">
          {{ authStore.isLoading ? '...' : '註冊' }}
        </button>
      </div>
    </div>
  </div>
</template>
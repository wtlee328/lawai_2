<script setup lang="ts">
import { Sun, Moon } from 'lucide-vue-next';
import { useTheme } from '../composables/useTheme';

const { theme, toggleTheme } = useTheme();
</script>

<template>
  <button
    @click="toggleTheme"
    class="p-2 rounded-md hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
    aria-label="Toggle theme"
  >
    <Sun v-if="theme === 'dark'" class="w-5 h-5" />
    <Moon v-else class="w-5 h-5" />
  </button>
</template>
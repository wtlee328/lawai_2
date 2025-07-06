import { ref, watchEffect, onMounted } from 'vue'

type Theme = 'light' | 'dark'

export function useTheme() {
  // Create a reactive reference for the theme.
  // It checks localStorage first, then the user's system preference.
  const theme = ref<Theme>(
    (localStorage.getItem('theme') as Theme) ||
    (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
  );

  // This effect runs whenever the `theme` ref changes.
  watchEffect(() => {
    // Add or remove the 'dark' class from the root <html> element.
    document.documentElement.classList.toggle('dark', theme.value === 'dark');
    // Save the user's preference to localStorage.
    localStorage.setItem('theme', theme.value);
  });

  // Function to toggle between light and dark mode.
  function toggleTheme() {
    theme.value = theme.value === 'light' ? 'dark' : 'light';
  }

  // Ensure the class is set on component mount as well.
  onMounted(() => {
    document.documentElement.classList.toggle('dark', theme.value === 'dark');
  });

  return {
    theme,
    toggleTheme
  };
}
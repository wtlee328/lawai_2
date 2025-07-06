/** @type {import('tailwindcss').Config} */
export default {
  // This is the critical part. It tells Tailwind to scan
  // all .vue, .js, and .ts files inside the src/ directory
  // and the main index.html file.
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  darkMode: 'class', // Make sure dark mode is enabled
  theme: {
    extend: {},
  },
  plugins: [],
}
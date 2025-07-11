import { createApp } from 'vue'
import { createPinia } from 'pinia' // Import Pinia
import App from './App.vue'
import router from './router' // Import our new router
import './style.css'
import { useAuthStore } from './store/auth'

const app = createApp(App)
const pinia = createPinia()

app.use(pinia) // Use Pinia for state management
app.use(router) // Use the router for navigation

// Initialize auth session
const authStore = useAuthStore()
authStore.initSession()

app.mount('#app')
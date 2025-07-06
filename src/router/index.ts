import { createRouter, createWebHistory } from 'vue-router'
import MainLayout from '../layouts/MainLayout.vue'
import { useAuthStore } from '../store/auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: () => import('../views/HomeView.vue')
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/LoginView.vue')
    },
    {
      path: '/workspace',
      component: MainLayout,
      meta: { requiresAuth: true }, // Add meta here to protect all children
      children: [
        {
          path: '',
          name: 'workspace',
          component: () => import('../views/WorkspaceView.vue'),
        }
      ]
    }
  ]
})

// Navigation Guard
router.beforeEach(async (to, _from, next) => {
  const authStore = useAuthStore();

  // Initialize the user session if it hasn't been done yet.
  // This is crucial for knowing the auth state on page load/refresh.
  if (authStore.user === null) {
    await authStore.initSession();
  }

  const requiresAuth = to.matched.some(record => record.meta.requiresAuth);
  const isAuthenticated = authStore.isAuthenticated;

  if (requiresAuth && !isAuthenticated) {
    // If route requires authentication and user is not logged in,
    // redirect to the login page.
    next({ name: 'login' });
  } else if ((to.name === 'login' || to.name === 'home') && isAuthenticated) {
    // If an authenticated user tries to access login or home page,
    // redirect them to their workspace.
    next({ name: 'workspace' });
  } else {
    // In all other cases, allow navigation.
    next();
  }
});

export default router
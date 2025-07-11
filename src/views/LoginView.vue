<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '../store/auth';


const authStore = useAuthStore();
const router = useRouter();

const email = ref('');
const password = ref('');
const showFeatures = ref(true);

// 自動切換顯示內容
onMounted(() => {
  setInterval(() => {
    showFeatures.value = !showFeatures.value;
  }, 4000); // 每4秒切換一次
});

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

const handleGoogleLogin = async () => {
  await authStore.loginWithGoogle();
};
</script>

<template>
  <div class="h-screen w-screen relative flex overflow-hidden">
    <!-- 背景圖片 -->
    <div class="absolute inset-0 bg-cover bg-center bg-no-repeat" style="background-image: url('/david-kidd-STWpM_WPrEs-unsplash.jpg')"></div>
    <!-- 背景遮罩 -->
     <div class="absolute inset-0 bg-black bg-opacity-25"></div>
    <!-- Left Side - App Introduction -->
     <div class="hidden lg:flex lg:w-1/2 flex-col relative px-12 xl:px-20 z-10">
      <!-- Logo 固定左上角 -->
       <div class="absolute top-8 left-8">
         <img src="/lawai_bw.svg" alt="Lawai Logo" class="h-10" />
       </div>

      <!-- 主要內容區 -->
      <div class="flex-1 flex flex-col justify-center max-w-lg mx-auto">
        <!-- 主標題 -->
        <div class="text-center mb-16">
          <h1 class="text-5xl font-bold text-white mb-6 animate-fade-in-up">
             精準搜索 <span class="bg-gradient-to-r from-cyan-300 to-cyan-400 bg-clip-text text-transparent">× 智能生成</span>
           </h1>
        </div>

        <!-- 內容切換容器 -->
        <div class="relative min-h-[400px]">
          <!-- 核心功能 -->
          <div class="absolute inset-0 space-y-6" :class="{ 'opacity-100': showFeatures, 'opacity-0': !showFeatures }" style="transition: opacity 0.5s ease-in-out;">
            <div class="group animate-slide-in-left animation-delay-500 cursor-pointer">
              <div class="flex items-center">
                <div class="w-3 h-3 bg-emerald-400 rounded-full mr-4 group-hover:scale-150 transition-all duration-300"></div>
                <span class="text-lg text-gray-100 group-hover:text-white transition-colors">判決書語義搜索</span>
              </div>
              <p class="text-m text-cyan-400 ml-7 mt-1">運用 AI 技術精準理解查詢意圖，快速找到相關判決</p>
            </div>
            
            <div class="group animate-slide-in-left animation-delay-700 cursor-pointer">
              <div class="flex items-center">
                <div class="w-3 h-3 bg-purple-400 rounded-full mr-4 group-hover:scale-150 transition-all duration-300"></div>
                <span class="text-lg text-gray-100 group-hover:text-white transition-colors">AI 書狀生成</span>
              </div>
              <p class="text-m text-cyan-400 ml-7 mt-1">基於判決書內容智能生成專業法律文件與書狀</p>
            </div>
            
            <div class="group animate-slide-in-left animation-delay-900 cursor-pointer">
              <div class="flex items-center">
                <div class="w-3 h-3 bg-orange-400 rounded-full mr-4 group-hover:scale-150 transition-all duration-300"></div>
                <span class="text-lg text-gray-100 group-hover:text-white transition-colors">高效案件分析</span>
              </div>
              <p class="text-m text-cyan-400 ml-7 mt-1">整合搜索並提供分析功能，大幅提升書狀編寫效率</p>
            </div>
          </div>

          <!-- 圖像化步驟流程 -->
          <div class="absolute inset-0" :class="{ 'opacity-100': !showFeatures, 'opacity-0': showFeatures }" style="transition: opacity 0.5s ease-in-out;">
            <div class="bg-white/5 backdrop-blur-sm rounded-2xl p-4 border border-white/10">
              <h3 class="text-white font-semibold text-base mb-4 text-center">智能法律助手工作流程</h3>
              
              <!-- 橫向步驟流程 -->
              <div class="space-y-4">
                <!-- 第一行：步驟 1 和 2 -->
                <div class="flex items-center justify-between">
                  <!-- 步驟 1 -->
                  <div class="flex-1 text-center">
                    <div class="relative">
                      <div class="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center mx-auto mb-2 shadow-lg">
                        <span class="text-white font-bold text-sm">1</span>
                      </div>
                      <h4 class="text-white font-medium text-xs mb-1">AI搜尋</h4>
                      <p class="text-cyan-300 text-xs leading-tight px-1">輸入案件基本資料，<br>由AI找出最適判決</p>
                    </div>
                  </div>
                  
                  <!-- 連接線 -->
                  <div class="flex-shrink-0 px-2">
                    <span class="text-2xl text-cyan-400">→</span>
                  </div>
                  
                  <!-- 步驟 2 -->
                  <div class="flex-1 text-center">
                    <div class="relative">
                      <div class="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center mx-auto mb-2 shadow-lg">
                        <span class="text-white font-bold text-sm">2</span>
                      </div>
                      <h4 class="text-white font-medium text-xs mb-1">智能生成</h4>
                      <p class="text-cyan-300 text-xs leading-tight px-1">AI判斷整理爭點<br>與邏輯生成文件</p>
                    </div>
                  </div>
                </div>
                
                <!-- 左下箭頭連接線 -->
                <div class="flex justify-center py-1">
                  <span class="text-2xl text-cyan-400">↙</span>
                </div>
                
                <!-- 第二行：步驟 3 和完成 -->
                <div class="flex items-center justify-between">
                  <!-- 步驟 3 -->
                  <div class="flex-1 text-center">
                    <div class="relative">
                      <div class="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center mx-auto mb-2 shadow-lg">
                        <span class="text-white font-bold text-sm">3</span>
                      </div>
                      <h4 class="text-white font-medium text-xs mb-1">AI聊天功能</h4>
                      <p class="text-cyan-300 text-xs leading-tight px-1">透過對話調整輸出結<br>果，獲得精準法律文件</p>
                    </div>
                  </div>
                  
                  <!-- 連接線 -->
                  <div class="flex-shrink-0 px-2">
                    <span class="text-2xl text-cyan-400">→</span>
                  </div>
                  
                  <!-- 完成 -->
                  <div class="flex-1 text-center">
                    <div class="relative">
                      <div class="w-12 h-12 bg-gradient-to-br from-green-500 to-green-600 rounded-full flex items-center justify-center mx-auto mb-2 shadow-lg">
                        <svg class="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 20 20">
                          <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
                        </svg>
                      </div>
                      <h4 class="text-white font-medium text-xs mb-1">完成！</h4>
                      <p class="text-cyan-300 text-xs leading-tight px-1">取得您需要的法律資訊<br>與文件</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 底部標語 -->
        <div class="text-center mt-16 animate-fade-in animation-delay-1100">
          <p class="text-gray-100">
            - 讓 AI 成為您的法律夥伴 -
          </p>
        </div>
      </div>
    </div>
    
    <!-- Right Side - Login Form -->
     <div class="w-full lg:w-1/2 flex items-center justify-center p-8 lg:p-12 z-10">
      <div class="w-full max-w-md">
        <!-- Mobile Logo -->
        <div class="lg:hidden flex items-center justify-center mb-8">
          <img src="/lawai_bw.svg" alt="Lawai Logo" class="h-10 mr-3" />
          <span class="text-2xl font-bold bg-gradient-to-r from-cyan-400 to-blue-500 bg-clip-text text-transparent">Lawai 2.0</span>
        </div>
        
        <!-- Login Card -->
        <div class="bg-white/0 backdrop-blur-lg rounded-2xl p-8 shadow-2xl border border-white/10">
          <div class="text-center mb-8">
            <h2 class="text-2xl font-bold text-white mb-2">歡迎回來！</h2>
            <p class="text-gray-300">登入您的帳戶以繼續使用 Lawai</p>
          </div>
          
          <!-- Email Input -->
          <div class="mb-6">
            <label for="email" class="block text-sm font-medium text-gray-200 mb-2">電子郵件地址</label>
            <input 
              v-model="email" 
              id="email" 
              type="email" 
              required 
              placeholder="your@example.com"
              class="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-cyan-400 focus:border-transparent transition-all"
            >
          </div>
          
          <!-- Password Input -->
          <div class="mb-6">
            <label for="password" class="block text-sm font-medium text-gray-200 mb-2">密碼</label>
            <input 
              v-model="password" 
              id="password" 
              type="password" 
              required 
              placeholder="輸入您的密碼"
              class="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-cyan-400 focus:border-transparent transition-all"
            >
          </div>

          <!-- Error Message -->
          <div v-if="authStore.error" class="mb-6 p-3 bg-red-500/20 border border-red-500/30 rounded-lg">
            <p class="text-red-300 text-sm">{{ authStore.error.message }}</p>
          </div>

          <!-- Login Button -->
          <button 
            @click="handleLogin" 
            :disabled="authStore.isLoading" 
            class="w-full py-3 px-4 bg-gradient-to-r from-cyan-500 to-blue-600 text-white font-semibold rounded-lg hover:from-cyan-600 hover:to-blue-700 focus:outline-none focus:ring-2 focus:ring-cyan-400 focus:ring-offset-2 focus:ring-offset-gray-900 disabled:opacity-50 disabled:cursor-not-allowed transition-all transform hover:scale-[1.02] active:scale-[0.98]"
          >
            {{ authStore.isLoading ? '登入中...' : '登入' }}
          </button>
          
          <!-- Divider -->
          <div class="my-6 flex items-center">
            <div class="flex-1 border-t border-white/20"></div>
            <span class="px-4 text-gray-400 text-sm">或</span>
            <div class="flex-1 border-t border-white/20"></div>
          </div>
          
          <!-- Social Login Buttons -->
          <div class="space-y-3">
            <button @click="handleGoogleLogin" :disabled="authStore.isLoading" class="w-full py-3 px-4 bg-white/10 border border-white/20 text-white rounded-lg hover:bg-white/20 focus:outline-none focus:ring-2 focus:ring-white/30 transition-all flex items-center justify-center disabled:opacity-50 disabled:cursor-not-allowed">
              <svg class="w-5 h-5 mr-3" viewBox="0 0 24 24">
                <path fill="currentColor" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                <path fill="currentColor" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                <path fill="currentColor" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                <path fill="currentColor" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
              </svg>
              使用 Google 帳戶登入
            </button>
            

          </div>
          
          <!-- Sign Up Link -->
          <div class="mt-8 text-center">
            <p class="text-gray-300 text-sm">
              還沒有帳戶？
              <button 
                @click="handleSignup" 
                :disabled="authStore.isLoading"
                class="text-cyan-400 hover:text-cyan-300 font-medium transition-colors disabled:opacity-50"
              >
                立即註冊
              </button>
            </p>
          </div>
        </div>
        
        <!-- Footer -->
        <div class="mt-8 text-center">
          <p class="text-gray-400 text-xs">
            © 2025 Lawai. All rights reserved.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(30px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes slideInLeft {
  from {
    opacity: 0;
    transform: translateX(-30px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

.animate-fade-in-up {
  animation: fadeInUp 0.8s ease-out forwards;
}

.animate-slide-in-left {
  animation: slideInLeft 0.6s ease-out forwards;
}

.animate-fade-in {
  animation: fadeIn 0.8s ease-out forwards;
}

.animation-delay-300 {
  animation-delay: 0.3s;
  opacity: 0;
}

.animation-delay-500 {
  animation-delay: 0.5s;
  opacity: 0;
}

.animation-delay-700 {
  animation-delay: 0.7s;
  opacity: 0;
}

.animation-delay-900 {
  animation-delay: 0.9s;
  opacity: 0;
}

.animation-delay-1100 {
  animation-delay: 1.1s;
  opacity: 0;
}
</style>
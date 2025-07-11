<template>
  <div class="flex h-full gap-6">
    <!-- 左側資料輸入區 -->
    <div class="flex-1 space-y-6 overflow-y-auto" style="flex-basis: 70%;">
      <!-- 基本資料 -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700">
        <div class="p-4 border-b border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white flex items-center">
            <svg class="w-5 h-5 mr-2 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
            </svg>
            基本資料
          </h3>
        </div>
        <div class="p-4 space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">文件類型</label>
              <select v-model="basicData.documentType" class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white">
                <option value="">請選擇文件類型</option>
                <option value="complaint">起訴狀</option>
                <option value="defense">答辯狀</option>
                <option value="appeal">上訴狀</option>
                <option value="motion">聲請狀</option>
              </select>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">案件編號</label>
              <input v-model="basicData.caseNumber" type="text" placeholder="請輸入案件編號" class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white" />
            </div>
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">法院</label>
              <input v-model="basicData.court" type="text" placeholder="請輸入法院名稱" class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">日期</label>
              <input v-model="basicData.date" type="date" class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white" />
            </div>
          </div>
        </div>
      </div>

      <!-- 當事人資料 -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700">
        <div class="p-4 border-b border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white flex items-center">
            <svg class="w-5 h-5 mr-2 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
            </svg>
            當事人資料
          </h3>
        </div>
        <div class="p-4 space-y-4">
          <!-- 原告/聲請人 -->
          <div>
            <h4 class="text-md font-medium text-gray-800 dark:text-gray-200 mb-3">原告/聲請人</h4>
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">姓名/名稱</label>
                <input v-model="partyData.plaintiff.name" type="text" placeholder="請輸入姓名或公司名稱" class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white" />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">身分證字號/統編</label>
                <input v-model="partyData.plaintiff.id" type="text" placeholder="請輸入身分證字號或統編" class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white" />
              </div>
            </div>
            <div class="mt-3">
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">地址</label>
              <input v-model="partyData.plaintiff.address" type="text" placeholder="請輸入地址" class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white" />
            </div>
          </div>
          
          <!-- 被告/相對人 -->
          <div>
            <h4 class="text-md font-medium text-gray-800 dark:text-gray-200 mb-3">被告/相對人</h4>
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">姓名/名稱</label>
                <input v-model="partyData.defendant.name" type="text" placeholder="請輸入姓名或公司名稱" class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white" />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">身分證字號/統編</label>
                <input v-model="partyData.defendant.id" type="text" placeholder="請輸入身分證字號或統編" class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white" />
              </div>
            </div>
            <div class="mt-3">
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">地址</label>
              <input v-model="partyData.defendant.address" type="text" placeholder="請輸入地址" class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white" />
            </div>
          </div>
        </div>
      </div>

      <!-- 案件內容 -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700">
        <div class="p-4 border-b border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white flex items-center">
            <svg class="w-5 h-5 mr-2 text-orange-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
            </svg>
            案件內容
          </h3>
        </div>
        <div class="p-4 space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">案件標題</label>
            <input v-model="caseContent.title" type="text" placeholder="請輸入案件標題" class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">事實概述</label>
            <textarea v-model="caseContent.facts" rows="4" placeholder="請描述案件事實" class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white resize-none"></textarea>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">法律依據</label>
            <textarea v-model="caseContent.legalBasis" rows="3" placeholder="請輸入相關法條或法律依據" class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white resize-none"></textarea>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">聲請/請求事項</label>
            <textarea v-model="caseContent.requests" rows="3" placeholder="請輸入具體的聲請或請求事項" class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white resize-none"></textarea>
          </div>
        </div>
      </div>

      <!-- 輔助資料 -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700">
        <div class="p-4 border-b border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white flex items-center">
            <svg class="w-5 h-5 mr-2 text-purple-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path>
            </svg>
            輔助資料
          </h3>
        </div>
        <div class="p-4 space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">相關判決書</label>
            <div v-if="selectedCases.length === 0" class="text-gray-500 dark:text-gray-400 text-sm py-4 text-center border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-lg">
              尚未選擇任何判決書，請從搜尋區選擇相關判決
            </div>
            <div v-else class="space-y-2">
              <div v-for="(case_, index) in selectedCases" :key="index" class="p-3 bg-gray-200 dark:bg-gray-700 rounded-lg">
                <div class="flex items-center justify-between">
                  <div class="flex-1">
                    <div class="text-sm font-medium text-gray-900 dark:text-white">{{ case_.title }}</div>
                    <div class="text-xs text-gray-500 dark:text-gray-400">{{ case_.court }} - {{ case_.date }}</div>
                  </div>
                  <div class="flex items-center space-x-1">
                    <button @click="toggleCaseExpansion(case_.case_id)" class="text-gray-500 hover:text-gray-700 p-1">
                      <svg class="w-4 h-4 transition-transform" :class="{ 'rotate-180': expandedCases.has(case_.case_id) }" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
                      </svg>
                    </button>
                    <button @click="removeCase(index)" class="text-red-500 hover:text-red-700 p-1">
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                      </svg>
                    </button>
                  </div>
                </div>
                <div v-if="expandedCases.has(case_.case_id) && case_.summary" class="mt-2 pt-2 border-t border-gray-300 dark:border-gray-600">
                  <div class="text-xs text-gray-600 dark:text-gray-300">{{ case_.summary }}</div>
                </div>
              </div>
            </div>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">其他附件</label>
            <textarea v-model="auxiliaryData.attachments" rows="2" placeholder="請列出其他相關附件或證據" class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white resize-none"></textarea>
          </div>
        </div>
      </div>
    </div>

    <!-- 右側生成文件顯示區 -->
    <div class="flex flex-col h-full overflow-y-auto" style="flex-basis: 30%;">
      <!-- 固定的資料完整性檢查和按鈕區域 -->
      <div ref="generateContainerRef" class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 sticky top-0 z-10">
        
        <!-- 未生成文件時顯示檢查清單 -->
        <div v-if="!isDocumentGenerated" class="p-4">
        <div class="space-y-3 mb-6">
          <h4 class="text-md font-medium text-gray-800 dark:text-gray-200 mb-3">資料完整性檢查</h4>
          
          <div class="flex items-center space-x-2">
            <div class="w-4 h-4 rounded-full flex items-center justify-center" :class="basicDataComplete ? 'bg-green-500' : 'bg-gray-300'">
              <svg v-if="basicDataComplete" class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
              </svg>
            </div>
            <span class="text-sm" :class="basicDataComplete ? 'text-green-600 dark:text-green-400' : 'text-gray-500 dark:text-gray-400'">基本資料</span>
          </div>
          
          <div class="flex items-center space-x-2">
            <div class="w-4 h-4 rounded-full flex items-center justify-center" :class="partyDataComplete ? 'bg-green-500' : 'bg-gray-300'">
              <svg v-if="partyDataComplete" class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
              </svg>
            </div>
            <span class="text-sm" :class="partyDataComplete ? 'text-green-600 dark:text-green-400' : 'text-gray-500 dark:text-gray-400'">當事人資料</span>
          </div>
          
          <div class="flex items-center space-x-2">
            <div class="w-4 h-4 rounded-full flex items-center justify-center" :class="caseContentComplete ? 'bg-green-500' : 'bg-gray-300'">
              <svg v-if="caseContentComplete" class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
              </svg>
            </div>
            <span class="text-sm" :class="caseContentComplete ? 'text-green-600 dark:text-green-400' : 'text-gray-500 dark:text-gray-400'">案件內容</span>
          </div>
          
          <div class="flex items-center space-x-2">
            <div class="w-4 h-4 rounded-full flex items-center justify-center" :class="auxiliaryDataComplete ? 'bg-green-500' : 'bg-gray-300'">
              <svg v-if="auxiliaryDataComplete" class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
              </svg>
            </div>
            <span class="text-sm" :class="auxiliaryDataComplete ? 'text-green-600 dark:text-green-400' : 'text-gray-500 dark:text-gray-400'">輔助資料</span>
          </div>
        </div>
        
          <div class="flex justify-center">
            <button 
              @click="generateDocument" 
              :disabled="!allDataComplete || isGenerating"
              class="w-48 py-3 px-4 rounded-lg font-medium transition-colors"
              :class="allDataComplete && !isGenerating ? 'bg-blue-600 hover:bg-blue-700 text-white' : 'bg-gray-300 dark:bg-gray-600 text-gray-500 dark:text-gray-400 cursor-not-allowed'"
            >
            <span v-if="isGenerating" class="flex items-center justify-center">
              <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              生成中...
            </span>
            <span v-else>生成文件</span>
            </button>
          </div>
        </div>
      </div>
      
      <!-- 文件生成後顯示的內容區域 -->
      <div v-if="isDocumentGenerated" class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 mt-4 flex-1 overflow-auto">
        <div class="p-4">
        <div class="mb-4 flex items-center justify-between">
          <h4 class="text-md font-medium text-gray-800 dark:text-gray-200">生成的文件</h4>
          <button @click="resetDocument" class="text-sm text-blue-600 hover:text-blue-800 dark:text-blue-400">
            重新生成
          </button>
        </div>
        <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4 max-h-96 overflow-y-auto">
          <div class="text-sm text-gray-900 dark:text-white whitespace-pre-wrap">{{ generatedDocument }}</div>
        </div>
          <div class="mt-4 flex space-x-2">
            <button class="flex-1 py-2 px-3 bg-blue-600 hover:bg-blue-700 text-white text-sm rounded-lg transition-colors">
              下載文件
            </button>
            <button class="flex-1 py-2 px-3 bg-gray-600 hover:bg-gray-700 text-white text-sm rounded-lg transition-colors">
              複製內容
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- 浮動簡潔版UI -->
  <div v-if="showFloatingUI && !isDocumentGenerated" class="fixed bottom-6 right-60 w-60 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 px-5 py-3 z-80">
    <div class="space-y-3">
      <!-- 第一行：文字 -->
      <div class="text-left">
        <h4 class="text-sm font-medium text-gray-800 dark:text-gray-200">
          {{ allDataComplete ? '文件生成' : '請完成輸入必要資料' }}
        </h4>
      </div>
      <!-- 第二行：進度UI和按鈕 -->
      <div class="flex items-center justify-between space-x-3">
        <div class="flex space-x-3">
          <div class="w-3 h-3 rounded-full flex items-center justify-center" :class="basicDataComplete ? 'bg-green-500' : 'bg-gray-300'">
            <svg v-if="basicDataComplete" class="w-2 h-2 text-white" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
            </svg>
          </div>
          <div class="w-3 h-3 rounded-full flex items-center justify-center" :class="partyDataComplete ? 'bg-green-500' : 'bg-gray-300'">
            <svg v-if="partyDataComplete" class="w-2 h-2 text-white" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
            </svg>
          </div>
          <div class="w-3 h-3 rounded-full flex items-center justify-center" :class="caseContentComplete ? 'bg-green-500' : 'bg-gray-300'">
            <svg v-if="caseContentComplete" class="w-2 h-2 text-white" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
            </svg>
          </div>
          <div class="w-3 h-3 rounded-full flex items-center justify-center" :class="auxiliaryDataComplete ? 'bg-green-500' : 'bg-gray-300'">
            <svg v-if="auxiliaryDataComplete" class="w-2 h-2 text-white" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
            </svg>
          </div>
        </div>
      <button 
        @click="generateDocument" 
        :disabled="!allDataComplete || isGenerating"
        class="py-2 px-4 rounded-md text-sm font-medium transition-colors whitespace-nowrap"
        :class="allDataComplete && !isGenerating ? 'bg-blue-600 hover:bg-blue-700 text-white' : 'bg-gray-300 dark:bg-gray-600 text-gray-500 dark:text-gray-400 cursor-not-allowed'"
      >
        <span v-if="isGenerating" class="flex items-center">
          <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          生成中...
        </span>
        <span v-else>生成文件</span>
      </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useWorkspaceStore } from '../store/workspace'
import { supabase } from '../supabase'

const workspaceStore = useWorkspaceStore()

// 浮動UI相關
const showFloatingUI = ref(false)
const generateContainerRef = ref<HTMLElement | null>(null)

// 定義事件
const emit = defineEmits<{
  'cases-selection-changed': []
}>()

// 定義案例介面
interface CaseItem {
  case_id: string
  title: string
  court: string
  date: string
  summary?: string
  relevance_score?: number
  [key: string]: any
}

// 資料模型
const basicData = ref({
  documentType: '',
  caseNumber: '',
  court: '',
  date: ''
})

const partyData = ref({
  plaintiff: {
    name: '',
    id: '',
    address: ''
  },
  defendant: {
    name: '',
    id: '',
    address: ''
  }
})

const caseContent = ref({
  title: '',
  facts: '',
  legalBasis: '',
  requests: ''
})

const auxiliaryData = ref({
  attachments: ''
})

const selectedCases = ref<CaseItem[]>([])
const expandedCases = ref<Set<string>>(new Set())
const isDocumentGenerated = ref(false)
const isGenerating = ref(false)
const generatedDocument = ref('')

// 載入已選擇的判決書
const loadSelectedCases = async () => {
  try {
    const cases = await workspaceStore.getSelectedCases()
    selectedCases.value = cases
  } catch (error) {
    console.error('載入已選擇判決書失敗:', error)
  }
}

// 組件掛載時載入已選擇的判決書
// Intersection Observer用於檢測容器可見性
let observer: IntersectionObserver | null = null

const checkContainerVisibility = () => {
  if (!generateContainerRef.value) return
  
  observer = new IntersectionObserver(
    (entries) => {
      const entry = entries[0]
      showFloatingUI.value = !entry.isIntersecting
    },
    {
      threshold: 0.1,
      rootMargin: '0px 0px -50px 0px'
    }
  )
  
  observer.observe(generateContainerRef.value)
}

onMounted(() => {
  loadSelectedCases()
  // 延遲檢查容器可見性，確保DOM已渲染
  setTimeout(checkContainerVisibility, 100)
})

onUnmounted(() => {
  if (observer) {
    observer.disconnect()
  }
})

// 監聽任務切換，重新載入已選擇的判決書
watch(() => workspaceStore.activeTaskId, () => {
  loadSelectedCases()
}, { immediate: true })

// 檢查資料完整性
const basicDataComplete = computed(() => {
  return basicData.value.documentType && basicData.value.caseNumber && basicData.value.court && basicData.value.date
})

const partyDataComplete = computed(() => {
  return partyData.value.plaintiff.name && partyData.value.plaintiff.id && 
         partyData.value.defendant.name && partyData.value.defendant.id
})

const caseContentComplete = computed(() => {
  return caseContent.value.title && caseContent.value.facts && caseContent.value.requests
})

const auxiliaryDataComplete = computed(() => {
  return selectedCases.value.length > 0 || auxiliaryData.value.attachments
})

const allDataComplete = computed(() => {
  return basicDataComplete.value && partyDataComplete.value && caseContentComplete.value && auxiliaryDataComplete.value
})

// 移除選中的案例
const removeCase = async (index: number) => {
  const caseToRemove = selectedCases.value[index]
  if (!caseToRemove) return
  
  try {
    // 先從本地陣列中移除，提供即時反饋
    selectedCases.value.splice(index, 1)
    
    // 從展開狀態中移除
    expandedCases.value.delete(caseToRemove.case_id)
    
    // 獲取所有包含該 case_id 的搜尋結果
    const { data: searchResults, error: fetchError } = await supabase
      .from('search_results')
      .select('id, added_to_doc_gen, case_ids')
      .eq('task_id', workspaceStore.activeTaskId)
    
    if (fetchError) {
      console.error('獲取搜尋結果失敗:', fetchError)
      // 即使資料庫查詢失敗，也要發射事件以更新UI
      emit('cases-selection-changed')
      return
    }
    
    // 在客戶端過濾包含該 case_id 的結果
    const relevantResults = searchResults?.filter(result => 
      result.case_ids && result.case_ids.includes(caseToRemove.case_id)
    ) || []
    
    // 更新所有相關的搜尋結果
    for (const result of relevantResults) {
      const updatedAddedToDocGen = {
        ...(result.added_to_doc_gen || {}),
        [caseToRemove.case_id]: 'n'
      }
      
      const { error: updateError } = await supabase
        .from('search_results')
        .update({ added_to_doc_gen: updatedAddedToDocGen })
        .eq('id', result.id)
      
      if (updateError) {
        console.error('更新搜尋結果失敗:', updateError)
      }
    }
    
    // 在所有資料庫操作完成後發射事件通知搜尋區更新
    emit('cases-selection-changed')
    
  } catch (error) {
    console.error('移除判決書失敗:', error)
    // 即使發生錯誤，也要發射事件以確保UI狀態同步
    emit('cases-selection-changed')
  }
}

// 切換案件摘要展開狀態
const toggleCaseExpansion = (caseId: string) => {
  if (expandedCases.value.has(caseId)) {
    expandedCases.value.delete(caseId)
  } else {
    expandedCases.value.add(caseId)
  }
}

// 生成文件
const generateDocument = async () => {
  isGenerating.value = true
  
  // 模擬文件生成過程
  setTimeout(() => {
    generatedDocument.value = `${basicData.value.documentType}

案件編號：${basicData.value.caseNumber}
法院：${basicData.value.court}
日期：${basicData.value.date}

原告：${partyData.value.plaintiff.name}
身分證字號：${partyData.value.plaintiff.id}
地址：${partyData.value.plaintiff.address}

被告：${partyData.value.defendant.name}
身分證字號：${partyData.value.defendant.id}
地址：${partyData.value.defendant.address}

案件標題：${caseContent.value.title}

事實：
${caseContent.value.facts}

法律依據：
${caseContent.value.legalBasis}

聲請事項：
${caseContent.value.requests}

此致
${basicData.value.court}

具狀人：${partyData.value.plaintiff.name}
中華民國 ${new Date().getFullYear()} 年 ${new Date().getMonth() + 1} 月 ${new Date().getDate()} 日`
    
    isDocumentGenerated.value = true
    isGenerating.value = false
  }, 2000)
}

// 重置文件
const resetDocument = () => {
  isDocumentGenerated.value = false
  generatedDocument.value = ''
}

// 暴露方法給父組件使用
defineExpose({
  loadSelectedCases
})
</script>
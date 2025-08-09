<template>
  <div class="p-6 max-w-4xl mx-auto">
    <h1 class="text-2xl font-bold mb-6">Multi-Field Search Test</h1>
    
    <!-- Test the SearchModule component -->
    <SearchModule />
    
    <!-- Test Information -->
    <div class="mt-8 p-4 bg-gray-100 dark:bg-gray-800 rounded-lg">
      <h2 class="text-lg font-semibold mb-3">Multi-Field Search Features:</h2>
      <ul class="space-y-2 text-sm">
        <li>✅ Search mode toggle (一般搜尋 ↔ 多欄位搜尋)</li>
        <li>✅ Four input fields: 判決內容, 爭點, 法院見解, 判決結果</li>
        <li>✅ Configurable field weights with sliders</li>
        <li>✅ Field similarity display in search results</li>
        <li>✅ Multi-field search API integration</li>
        <li>✅ Enhanced UI with color-coded field indicators</li>
      </ul>
      
      <div class="mt-4 p-3 bg-blue-50 dark:bg-gray-700 rounded">
        <h3 class="font-medium mb-2">Test Instructions:</h3>
        <ol class="text-sm space-y-1">
          <li>1. Click "多欄位搜尋" to enable multi-field mode</li>
          <li>2. Enter different queries in the field inputs</li>
          <li>3. Adjust field weights using the sliders</li>
          <li>4. Click "開始多欄位搜尋" to test the search</li>
          <li>5. Check the field similarity bars in results</li>
        </ol>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import SearchModule from './SearchModule.vue'
</script>
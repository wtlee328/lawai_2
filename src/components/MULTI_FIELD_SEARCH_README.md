# Multi-Field Search Implementation

## Overview

The `SearchModule.vue` component has been enhanced with comprehensive multi-field semantic search capabilities, allowing users to search across different sections of legal cases with weighted scoring.

## Features

### 🎯 **Dual Search Modes**
- **一般搜尋 (Single Field)**: Traditional search with one query input
- **多欄位搜尋 (Multi-Field)**: Advanced search across multiple case sections

### 📝 **Multi-Field Input System**
- **判決內容 (Content)**: Full case content search
- **爭點 (Dispute)**: Dispute points and legal issues
- **法院見解 (Opinion)**: Court's legal opinion and reasoning  
- **判決結果 (Result)**: Final judgment and outcome

### ⚖️ **Configurable Field Weights**
- Default weights: Content (40%), Dispute (30%), Opinion (20%), Result (10%)
- Interactive sliders for real-time weight adjustment
- Reset to default weights functionality
- Visual weight indicators

### 📊 **Enhanced Results Display**
- Individual similarity scores for each field
- Color-coded progress bars for field relevance
- Combined weighted similarity scoring
- Multi-field search indicators

### 🎨 **Improved UI/UX**
- Smooth mode transitions with animations
- Color-coded field indicators (blue, orange, green, purple)
- Responsive grid layout for field inputs
- Collapsible weight adjustment panel

## Component Structure

### Reactive Variables

```typescript
// Search modes
const isMultiFieldMode = ref(false)
const showWeightAdjustment = ref(false)

// Multi-field queries
const multiFieldQuery = ref({
  content: '',    // 判決內容
  dispute: '',    // 爭點  
  opinion: '',    // 法院見解
  result: ''      // 判決結果
})

// Field weights
const fieldWeights = ref({
  content: 0.4,
  dispute: 0.3,
  opinion: 0.2,
  result: 0.1
})
```

### Key Methods

```typescript
// Multi-field search execution
async function handleSearch()

// Clear all multi-field inputs
function clearMultiFieldQuery()

// Reset weights to defaults
function resetWeights()

// Enhanced search validation
const canSearch = computed(() => {
  if (isMultiFieldMode.value) {
    const hasMultiFieldQuery = Object.values(multiFieldQuery.value)
      .some(query => query && query.trim())
    return !isLoading.value && hasMultiFieldQuery
  }
  return !isLoading.value && searchQuery.value.trim().length > 0
})
```

## API Integration

### Multi-Field Search Request

```javascript
// Multi-field search payload
const requestBody = {
  query: {
    content: multiFieldQuery.value.content || null,
    dispute: multiFieldQuery.value.dispute || null,
    opinion: multiFieldQuery.value.opinion || null,
    result: multiFieldQuery.value.result || null
  },
  search_methods: ['multi_field_semantic'],
  field_weights: { ...fieldWeights.value },
  filters: {},
  limit: 25
}
```

### Response Processing

```javascript
// Enhanced result processing with field similarities
const resultsWithDocGen = data.results.map((result) => ({
  ...result,
  added_to_doc_gen: result.added_to_doc_gen || null,
  field_similarities: result.field_similarities || null
}))

searchResult.value = {
  query: isMultiFieldMode.value ? multiFieldQuery.value : searchQuery.value,
  results: resultsWithDocGen,
  total_count: data.total_count,
  search_type: isMultiFieldMode.value ? 'multi-field' : 'single-field',
  field_weights: isMultiFieldMode.value ? { ...fieldWeights.value } : null
}
```

## UI Components

### Mode Toggle

```vue
<div class="flex gap-2">
  <button 
    @click="isMultiFieldMode = false; selectedSearchMethod = 'hybrid'"
    :class="!isMultiFieldMode ? 'bg-blue-500 text-white' : 'bg-white text-blue-600'"
  >
    一般搜尋
  </button>
  <button 
    @click="isMultiFieldMode = true; selectedSearchMethod = 'multi_field_semantic'"
    :class="isMultiFieldMode ? 'bg-purple-500 text-white' : 'bg-white text-purple-600'"
  >
    多欄位搜尋
  </button>
</div>
```

### Field Input Grid

```vue
<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
  <!-- 判決內容 -->
  <div class="space-y-2">
    <label class="flex items-center gap-2">
      <svg class="w-4 h-4 text-blue-500">...</svg>
      判決內容
    </label>
    <input
      v-model="multiFieldQuery.content"
      placeholder="搜尋判決內容..."
      @keyup.enter="handleSearch"
    />
  </div>
  <!-- Additional fields... -->
</div>
```

### Field Similarity Display

```vue
<div v-if="isMultiFieldMode && result.field_similarities" class="field-similarities">
  <div class="grid grid-cols-2 gap-3">
    <div v-if="result.field_similarities.content > 0">
      <div class="flex justify-between">
        <span>判決內容</span>
        <span>{{ Math.round(result.field_similarities.content * 100) }}%</span>
      </div>
      <div class="progress-bar">
        <div 
          class="bg-gradient-to-r from-blue-400 to-blue-500"
          :style="{ width: (result.field_similarities.content * 100) + '%' }"
        ></div>
      </div>
    </div>
    <!-- Additional similarity bars... -->
  </div>
</div>
```

### Weight Adjustment Panel

```vue
<div v-if="showWeightAdjustment" class="weight-panel">
  <div class="space-y-3">
    <div class="space-y-2">
      <div class="flex justify-between">
        <label>判決內容</label>
        <span>{{ (fieldWeights.content * 100).toFixed(0) }}%</span>
      </div>
      <input
        type="range"
        v-model.number="fieldWeights.content"
        min="0" max="1" step="0.1"
        class="slider-blue"
      />
    </div>
    <!-- Additional weight sliders... -->
  </div>
</div>
```

## Styling

### Custom Slider Styles

```css
.slider-blue::-webkit-slider-thumb {
  appearance: none;
  height: 16px;
  width: 16px;
  border-radius: 50%;
  background: linear-gradient(45deg, #3b82f6, #1d4ed8);
  cursor: pointer;
  box-shadow: 0 2px 4px rgba(59, 130, 246, 0.3);
}

/* Additional color variants for orange, green, purple */
```

### Field Color Coding

- **判決內容 (Content)**: Blue (#3b82f6)
- **爭點 (Dispute)**: Orange (#f97316)  
- **法院見解 (Opinion)**: Green (#10b981)
- **判決結果 (Result)**: Purple (#8b5cf6)

## Usage Examples

### Basic Multi-Field Search

```vue
<template>
  <SearchModule />
</template>

<script setup>
import SearchModule from '@/components/SearchModule.vue'
</script>
```

### Testing Component

```vue
<template>
  <MultiFieldSearchTest />
</template>

<script setup>
import MultiFieldSearchTest from '@/components/MultiFieldSearchTest.vue'
</script>
```

## Backend Requirements

### API Endpoints

- `POST /multi-field` - Multi-field semantic search
- `POST /unified` - Unified search supporting both modes

### Expected Response Format

```json
{
  "success": true,
  "results": [
    {
      "case_id": "...",
      "relevance_score": 0.85,
      "field_similarities": {
        "content": 0.9,
        "dispute": 0.8,
        "opinion": 0.7,
        "result": 0.6
      },
      "content": "...",
      "dispute": "...",
      "opinion": "...",
      "result": "..."
    }
  ],
  "total_count": 25
}
```

## Performance Considerations

### Optimization Features

1. **Conditional Rendering**: UI elements only render when needed
2. **Debounced Weight Updates**: Smooth slider interactions
3. **Efficient State Management**: Minimal re-renders
4. **Progressive Enhancement**: Graceful fallback to single-field mode

### Best Practices

1. **Field Weight Balance**: Ensure weights sum to reasonable values
2. **Query Validation**: At least one field must have content
3. **Result Limiting**: Use appropriate limits (25-50) for performance
4. **Error Handling**: Graceful degradation on API failures

## Migration Guide

### From Single-Field to Multi-Field

1. **Existing Queries**: Automatically work in single-field mode
2. **State Preservation**: Search history and preferences maintained
3. **Backward Compatibility**: All existing functionality preserved
4. **Progressive Enhancement**: New features available without breaking changes

### Configuration Updates

```javascript
// Update available search methods
const availableSearchMethods = [
  { value: 'hybrid', label: '混合搜尋' },
  { value: 'semantic', label: '語意搜尋' },
  { value: 'keyword', label: '關鍵字搜尋' },
  { value: 'category', label: '類別搜尋' },
  { value: 'multi_field_semantic', label: '多欄位語意' } // New
]
```

## Troubleshooting

### Common Issues

1. **No Results**: Check if at least one field has content
2. **Weight Issues**: Ensure weights are between 0.0-1.0
3. **API Errors**: Verify backend multi-field endpoint availability
4. **UI Glitches**: Check for proper conditional rendering

### Debug Tips

```javascript
// Log multi-field query state
console.log('Multi-field query:', multiFieldQuery.value)
console.log('Field weights:', fieldWeights.value)
console.log('Search mode:', isMultiFieldMode.value)
```

The multi-field search implementation provides a comprehensive, user-friendly interface for advanced legal case searching with weighted field relevance scoring! 🚀
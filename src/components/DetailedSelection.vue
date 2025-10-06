<template>
  <div class="detailed-selection">
    <div class="section" v-if="category === 'personnel'">
      <h4>选择人员 ({{ selectedItems.length }}/{{ items.length }})</h4>
      <div class="item-list">
        <label v-for="item in items" :key="item.id" class="item-checkbox">
          <input
            type="checkbox"
            :value="item.id"
            v-model="selectedItems"
            @change="emitChange"
          />
          <span class="item-info">
            <strong>{{ item.name }}</strong>
            <small v-if="item.phone">{{ item.phone }}</small>
          </span>
        </label>
      </div>
    </div>

    <div class="section" v-else-if="category === 'qualifications'">
      <h4>选择资质 ({{ selectedItems.length }}/{{ items.length }})</h4>
      <div class="item-list">
        <label v-for="item in items" :key="item.id" class="item-checkbox">
          <input
            type="checkbox"
            :value="item.id"
            v-model="selectedItems"
            @change="emitChange"
          />
          <span class="item-info">
            <strong>{{ item.qualification_name }}</strong>
            <small v-if="item.certificate_number">证书编号: {{ item.certificate_number }}</small>
          </span>
        </label>
      </div>
    </div>

    <div class="section" v-else-if="category === 'performance'">
      <h4>选择业绩 ({{ selectedItems.length }}/{{ items.length }})</h4>
      <div class="item-list">
        <label v-for="item in items" :key="item.id" class="item-checkbox">
          <input
            type="checkbox"
            :value="item.id"
            v-model="selectedItems"
            @change="emitChange"
          />
          <span class="item-info">
            <strong>{{ item.project_name }}</strong>
            <small v-if="item.client_name">客户: {{ item.client_name }}</small>
          </span>
        </label>
      </div>
    </div>

    <div class="section" v-else-if="category === 'financial'">
      <h4>选择财务信息 ({{ selectedItems.length }}/{{ items.length }})</h4>
      <div class="item-list">
        <label v-for="item in items" :key="item.id" class="item-checkbox">
          <input
            type="checkbox"
            :value="item.id"
            v-model="selectedItems"
            @change="emitChange"
          />
          <span class="item-info">
            <strong>{{ item.year }}年度</strong>
            <small v-if="item.revenue">营收: {{ formatCurrency(item.revenue) }}</small>
          </span>
        </label>
      </div>
    </div>

    <div class="section" v-else-if="category === 'historical'">
      <h4>选择历史投标文件 ({{ selectedItems.length }}/{{ items.length }})</h4>
      <div class="item-list">
        <label v-for="item in items" :key="item.id" class="item-checkbox">
          <input
            type="checkbox"
            :value="item.id"
            v-model="selectedItems"
            @change="emitChange"
          />
          <span class="item-info">
            <strong>{{ item.project_name }}</strong>
            <small>{{ item.bid_type }} - {{ item.document_type }}</small>
          </span>
        </label>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'

const props = defineProps<{
  category: string
  items: any[]
  modelValue: string[]
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: string[]): void
}>()

const selectedItems = ref<string[]>(props.modelValue || [])

watch(() => props.modelValue, (newValue) => {
  selectedItems.value = newValue || []
})

const emitChange = () => {
  emit('update:modelValue', selectedItems.value)
}

const formatCurrency = (value: number | null) => {
  if (value === null) return '-'
  return new Intl.NumberFormat('zh-CN', {
    style: 'currency',
    currency: 'CNY',
    minimumFractionDigits: 0
  }).format(value)
}
</script>

<style scoped>
.detailed-selection {
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  overflow: hidden;
}

.section {
  padding: 16px;
}

.section h4 {
  margin: 0 0 12px 0;
  font-size: 14px;
  color: #333;
  font-weight: 600;
}

.item-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-height: 300px;
  overflow-y: auto;
  padding: 8px;
  background: #f9f9f9;
  border-radius: 6px;
}

.item-checkbox {
  display: flex;
  align-items: flex-start;
  padding: 10px;
  background: white;
  border: 1px solid #e0e0e0;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
  margin: 0;
}

.item-checkbox:hover {
  border-color: #2663eb;
  background: #f8f9ff;
}

.item-checkbox input[type="checkbox"] {
  margin-right: 10px;
  margin-top: 2px;
  width: auto;
  flex-shrink: 0;
}

.item-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.item-info strong {
  color: #333;
  font-size: 14px;
}

.item-info small {
  color: #666;
  font-size: 12px;
}
</style>

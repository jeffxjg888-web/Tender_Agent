<template>
  <Transition name="toast">
    <div v-if="visible" class="toast-container" :class="type">
      <div class="toast-content">
        <div class="toast-icon">{{ icon }}</div>
        <div class="toast-message">
          <div class="toast-title">{{ title }}</div>
          <div class="toast-text">{{ message }}</div>
        </div>
        <button class="toast-close" @click="close">×</button>
      </div>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'

interface Props {
  title?: string
  message: string
  type?: 'success' | 'error' | 'warning' | 'info'
  duration?: number
  show?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  title: '',
  type: 'info',
  duration: 3000,
  show: false
})

const emit = defineEmits<{
  close: []
}>()

const visible = ref(false)
let timer: NodeJS.Timeout | null = null

const icon = computed(() => {
  const icons = {
    success: '✓',
    error: '✕',
    warning: '⚠',
    info: 'ℹ'
  }
  return icons[props.type]
})

watch(() => props.show, (newVal) => {
  if (newVal) {
    visible.value = true
    if (timer) clearTimeout(timer)
    if (props.duration > 0) {
      timer = setTimeout(() => {
        close()
      }, props.duration)
    }
  }
})

const close = () => {
  visible.value = false
  if (timer) clearTimeout(timer)
  emit('close')
}
</script>

<style scoped>
.toast-container {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  z-index: 9999;
  min-width: 320px;
  max-width: 500px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.12), 0 2px 8px rgba(0, 0, 0, 0.08);
  overflow: hidden;
}

.toast-content {
  display: flex;
  align-items: flex-start;
  padding: 20px;
  gap: 16px;
}

.toast-icon {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  font-weight: bold;
  flex-shrink: 0;
}

.toast-container.success .toast-icon {
  background: #dcfce7;
  color: #16a34a;
}

.toast-container.error .toast-icon {
  background: #fee2e2;
  color: #dc2626;
}

.toast-container.warning .toast-icon {
  background: #fef3c7;
  color: #d97706;
}

.toast-container.info .toast-icon {
  background: #dbeafe;
  color: #2563eb;
}

.toast-message {
  flex: 1;
  min-width: 0;
}

.toast-title {
  font-size: 16px;
  font-weight: 600;
  color: #111827;
  margin-bottom: 4px;
}

.toast-text {
  font-size: 14px;
  color: #6b7280;
  line-height: 1.5;
}

.toast-close {
  width: 24px;
  height: 24px;
  border-radius: 6px;
  background: transparent;
  border: none;
  color: #9ca3af;
  font-size: 24px;
  cursor: pointer;
  padding: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  transition: all 0.2s;
}

.toast-close:hover {
  background: #f3f4f6;
  color: #374151;
}

.toast-enter-active,
.toast-leave-active {
  transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
}

.toast-enter-from {
  opacity: 0;
  transform: translate(-50%, -50%) scale(0.9);
}

.toast-leave-to {
  opacity: 0;
  transform: translate(-50%, -50%) scale(0.95);
}
</style>

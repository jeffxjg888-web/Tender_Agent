import { ref } from 'vue'

interface ToastOptions {
  title?: string
  message: string
  type?: 'success' | 'error' | 'warning' | 'info'
  duration?: number
}

interface ToastItem extends ToastOptions {
  id: number
  show: boolean
}

export const toasts = ref<ToastItem[]>([])
let toastId = 0

export const showToast = (options: ToastOptions) => {
  const id = toastId++
  const toast: ToastItem = {
    id,
    show: true,
    type: options.type || 'info',
    title: options.title || '',
    message: options.message,
    duration: options.duration !== undefined ? options.duration : 3000
  }

  toasts.value.push(toast)

  if (toast.duration && toast.duration > 0) {
    setTimeout(() => {
      removeToast(id)
    }, toast.duration)
  }
}

export const removeToast = (id: number) => {
  const index = toasts.value.findIndex(t => t.id === id)
  if (index > -1) {
    toasts.value[index].show = false
    setTimeout(() => {
      toasts.value.splice(index, 1)
    }, 300)
  }
}

export const toast = {
  success: (message: string, title?: string) => {
    showToast({ message, title, type: 'success' })
  },
  error: (message: string, title?: string) => {
    showToast({ message, title, type: 'error' })
  },
  warning: (message: string, title?: string) => {
    showToast({ message, title, type: 'warning' })
  },
  info: (message: string, title?: string) => {
    showToast({ message, title, type: 'info' })
  }
}

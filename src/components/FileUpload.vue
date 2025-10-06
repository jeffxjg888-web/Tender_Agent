<template>
  <div class="file-upload">
    <div
      class="upload-area"
      :class="{ 'dragging': isDragging, 'has-file': fileInfo }"
      @click="triggerFileInput"
      @drop.prevent="handleDrop"
      @dragover.prevent="isDragging = true"
      @dragleave.prevent="isDragging = false"
    >
      <input
        ref="fileInput"
        type="file"
        :accept="accept"
        @change="handleFileChange"
        style="display: none"
      />

      <div v-if="!fileInfo" class="upload-placeholder">
        <div class="upload-icon">📁</div>
        <p class="upload-text">点击或拖拽文件到此处上传</p>
        <p class="upload-hint">{{ acceptText }}</p>
      </div>

      <div v-else class="file-info">
        <div class="file-icon">📄</div>
        <div class="file-details">
          <p class="file-name">{{ fileInfo.name }}</p>
          <p class="file-size">{{ formatFileSize(fileInfo.size) }}</p>
        </div>
        <button
          type="button"
          class="remove-btn"
          @click.stop="removeFile"
          :disabled="uploading"
        >
          ✕
        </button>
      </div>

      <div v-if="uploading" class="upload-progress">
        <div class="progress-bar">
          <div class="progress-bar-fill" :style="{ width: uploadProgress + '%' }"></div>
        </div>
        <p class="progress-text">上传中... {{ uploadProgress }}%</p>
      </div>
    </div>

    <p v-if="error" class="error-message">{{ error }}</p>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { supabase } from '../lib/supabase'

interface Props {
  accept?: string
  acceptText?: string
  bucket?: string
  maxSize?: number
}

const props = withDefaults(defineProps<Props>(), {
  accept: '*',
  acceptText: '支持所有文件格式',
  bucket: 'documents',
  maxSize: 50 * 1024 * 1024
})

const emit = defineEmits<{
  uploaded: [url: string, file: File]
  error: [message: string]
}>()

const fileInput = ref<HTMLInputElement>()
const fileInfo = ref<File | null>(null)
const isDragging = ref(false)
const uploading = ref(false)
const uploadProgress = ref(0)
const error = ref('')

const triggerFileInput = () => {
  if (!uploading.value) {
    fileInput.value?.click()
  }
}

const handleFileChange = (event: Event) => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  if (file) {
    validateAndSetFile(file)
  }
}

const handleDrop = (event: DragEvent) => {
  isDragging.value = false
  const file = event.dataTransfer?.files?.[0]
  if (file) {
    validateAndSetFile(file)
  }
}

const validateAndSetFile = (file: File) => {
  error.value = ''

  if (file.size > props.maxSize) {
    error.value = `文件大小超过限制（最大${formatFileSize(props.maxSize)}）`
    emit('error', error.value)
    return
  }

  fileInfo.value = file
  uploadFile(file)
}

const uploadFile = async (file: File) => {
  uploading.value = true
  uploadProgress.value = 0
  error.value = ''

  try {
    const fileExt = file.name.split('.').pop()
    const fileName = `${Date.now()}-${Math.random().toString(36).substring(2)}.${fileExt}`
    const filePath = `${fileName}`

    const progressInterval = setInterval(() => {
      if (uploadProgress.value < 90) {
        uploadProgress.value += 10
      }
    }, 200)

    const { error: uploadError } = await supabase.storage
      .from(props.bucket)
      .upload(filePath, file, {
        cacheControl: '3600',
        upsert: false
      })

    clearInterval(progressInterval)

    if (uploadError) throw uploadError

    const { data: urlData } = supabase.storage
      .from(props.bucket)
      .getPublicUrl(filePath)

    uploadProgress.value = 100

    setTimeout(() => {
      emit('uploaded', urlData.publicUrl, file)
    }, 300)

  } catch (err: any) {
    error.value = err.message || '上传失败'
    emit('error', error.value)
    fileInfo.value = null
  } finally {
    uploading.value = false
  }
}

const removeFile = () => {
  fileInfo.value = null
  uploadProgress.value = 0
  error.value = ''
  if (fileInput.value) {
    fileInput.value.value = ''
  }
}

const formatFileSize = (bytes: number): string => {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
}
</script>

<style scoped>
.file-upload {
  width: 100%;
}

.upload-area {
  border: 2px dashed #d1d5db;
  border-radius: 12px;
  padding: 32px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s ease;
  background: #fafbfc;
}

.upload-area:hover {
  border-color: #667eea;
  background: #f8f9ff;
}

.upload-area.dragging {
  border-color: #667eea;
  background: #f0f4ff;
  transform: scale(1.02);
}

.upload-area.has-file {
  border-style: solid;
  border-color: #667eea;
  background: white;
}

.upload-placeholder {
  pointer-events: none;
}

.upload-icon {
  font-size: 48px;
  margin-bottom: 16px;
  opacity: 0.6;
}

.upload-text {
  font-size: 16px;
  font-weight: 500;
  color: #374151;
  margin-bottom: 8px;
}

.upload-hint {
  font-size: 14px;
  color: #6b7280;
}

.file-info {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px;
  background: #f9fafb;
  border-radius: 8px;
}

.file-icon {
  font-size: 36px;
}

.file-details {
  flex: 1;
  text-align: left;
}

.file-name {
  font-size: 15px;
  font-weight: 600;
  color: #111827;
  margin-bottom: 4px;
  word-break: break-all;
}

.file-size {
  font-size: 13px;
  color: #6b7280;
}

.remove-btn {
  width: 32px;
  height: 32px;
  min-width: 32px;
  padding: 0;
  border-radius: 50%;
  background: #ef4444;
  color: white;
  font-size: 18px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 6px rgba(239, 68, 68, 0.3);
}

.remove-btn:hover {
  background: #dc2626;
}

.upload-progress {
  margin-top: 16px;
}

.progress-text {
  margin-top: 8px;
  font-size: 13px;
  color: #667eea;
  font-weight: 500;
}

.error-message {
  margin-top: 12px;
  color: #ef4444;
  font-size: 14px;
  font-weight: 500;
}
</style>

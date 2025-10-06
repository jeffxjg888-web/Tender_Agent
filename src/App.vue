<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import Layout from './components/Layout.vue'
import Toast from './components/Toast.vue'
import { toasts, removeToast } from './lib/toast'

const route = useRoute()

const showLayout = computed(() => {
  return !route.meta.public
})
</script>

<template>
  <Layout v-if="showLayout" />
  <router-view v-else />

  <Toast
    v-for="toast in toasts"
    :key="toast.id"
    :title="toast.title"
    :message="toast.message"
    :type="toast.type"
    :duration="toast.duration"
    :show="toast.show"
    @close="removeToast(toast.id)"
  />
</template>

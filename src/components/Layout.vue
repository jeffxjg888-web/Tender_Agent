<template>
  <div class="layout">
    <aside class="sidebar">
      <div class="logo">
        <h2>标书智能体系统</h2>
      </div>
      <nav class="nav">
        <router-link
          v-for="item in menuItems"
          :key="item.path"
          :to="item.path"
          class="nav-item"
          active-class="active"
        >
          <span class="nav-icon">{{ item.icon }}</span>
          <span class="nav-text">{{ item.title }}</span>
        </router-link>
      </nav>
      <div class="user-section">
        <div class="user-info">
          <div class="user-avatar">{{ userInitial }}</div>
          <div class="user-details">
            <div class="user-name">{{ userName }}</div>
            <div class="user-email">{{ userEmail }}</div>
          </div>
        </div>
        <button class="logout-btn" @click="handleLogout">退出</button>
      </div>
    </aside>
    <main class="main-content">
      <header class="header">
        <h1>{{ currentTitle }}</h1>
      </header>
      <div class="content">
        <router-view />
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '../lib/supabase'

const route = useRoute()
const router = useRouter()

const userName = ref('用户')
const userEmail = ref('user@example.com')

const menuItems = [
  { path: '/knowledge', title: '企业知识库管理', icon: '📚' },
  { path: '/tender', title: '招标文件管理', icon: '📄' },
  { path: '/bid-generation', title: '标书生成', icon: '✏️' },
  { path: '/bid-check', title: '标书检查', icon: '✓' },
  { path: '/settings', title: '系统设置', icon: '⚙️' }
]

const currentTitle = computed(() => {
  return route.meta.title as string || '标书智能体系统'
})

const userInitial = computed(() => {
  return userName.value.charAt(0).toUpperCase()
})

const handleLogout = async () => {
  if (confirm('确定要退出登录吗？')) {
    await supabase.auth.signOut()
    router.push('/login')
  }
}

onMounted(async () => {
  const { data: { user } } = await supabase.auth.getUser()
  if (user?.email) {
    userEmail.value = user.email

    const { data: userData } = await supabase
      .from('users')
      .select('full_name')
      .eq('id', user.id)
      .maybeSingle()

    if (userData?.full_name) {
      userName.value = userData.full_name
    }
  }
})
</script>

<style scoped>
.layout {
  display: flex;
  height: 100vh;
  background: #ffffff;
}

.sidebar {
  width: 260px;
  background: #2663eb;
  color: white;
  display: flex;
  flex-direction: column;
  box-shadow: 2px 0 10px rgba(38, 99, 235, 0.1);
}

.logo {
  padding: 20px 20px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  text-align: center;
}

.logo h2 {
  margin: 0;
  font-size: 28px;
  font-weight: 700;
  color: white;
  letter-spacing: 0.5px;
}

.nav {
  flex: 1;
  padding: 12px 12px;
  overflow-y: auto;
}

.nav-item {
  display: flex;
  align-items: center;
  padding: 10px 16px;
  margin-bottom: 4px;
  color: rgba(255, 255, 255, 0.85);
  text-decoration: none;
  transition: all 0.3s ease;
  border-radius: 8px;
  position: relative;
}

.nav-item::before {
  content: '';
  position: absolute;
  left: 0;
  top: 50%;
  transform: translateY(-50%);
  width: 3px;
  height: 0;
  background: white;
  border-radius: 0 3px 3px 0;
  transition: height 0.3s ease;
}

.nav-item:hover {
  background: rgba(255, 255, 255, 0.15);
  color: white;
}

.nav-item:hover::before {
  height: 60%;
}

.nav-item.active {
  background: rgba(255, 255, 255, 0.2);
  color: white;
}

.nav-item.active::before {
  height: 70%;
}

.nav-icon {
  font-size: 20px;
  margin-right: 12px;
}

.nav-text {
  font-size: 14px;
  font-weight: 500;
}

.user-section {
  padding: 16px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
}

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
}

.user-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: 16px;
}

.user-details {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.user-name {
  font-size: 14px;
  color: white;
  font-weight: 600;
}

.user-email {
  font-size: 11px;
  color: rgba(255, 255, 255, 0.7);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.logout-btn {
  width: 100%;
  padding: 8px;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: white;
  font-size: 13px;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.logout-btn:hover {
  background: rgba(255, 255, 255, 0.2);
  transform: none;
}

.main-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.header {
  background: white;
  padding: 20px 32px;
  border-bottom: 1px solid #e8ecef;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.header h1 {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
  color: #1a1a1a;
}

.content {
  flex: 1;
  padding: 24px 32px;
  overflow-y: auto;
  background: #ffffff;
}

.content::-webkit-scrollbar {
  width: 8px;
}

.content::-webkit-scrollbar-track {
  background: #f5f5f5;
}

.content::-webkit-scrollbar-thumb {
  background: #2663eb;
  border-radius: 4px;
}

.content::-webkit-scrollbar-thumb:hover {
  background: #1d4ec4;
}
</style>

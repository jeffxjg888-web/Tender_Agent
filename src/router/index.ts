import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'
import { supabase } from '../lib/supabase'

const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'login',
    component: () => import('../views/Login.vue'),
    meta: { public: true }
  },
  {
    path: '/',
    name: 'home',
    redirect: '/knowledge'
  },
  {
    path: '/knowledge',
    name: 'knowledge',
    component: () => import('../views/KnowledgeManagement.vue'),
    meta: { title: '企业知识库管理' }
  },
  {
    path: '/tender',
    name: 'tender',
    component: () => import('../views/TenderManagement.vue'),
    meta: { title: '招标文件管理' }
  },
  {
    path: '/bid-generation',
    name: 'bidGeneration',
    component: () => import('../views/BidGeneration.vue'),
    meta: { title: '标书生成' }
  },
  {
    path: '/bid-check',
    name: 'bidCheck',
    component: () => import('../views/BidCheck.vue'),
    meta: { title: '标书检查' }
  },
  {
    path: '/settings',
    name: 'settings',
    component: () => import('../views/SystemSettings.vue'),
    meta: { title: '系统设置' }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach(async (to, _from, next) => {
  const { data: { session } } = await supabase.auth.getSession()

  if (!to.meta.public && !session) {
    next('/login')
  } else if (to.path === '/login' && session) {
    next('/knowledge')
  } else {
    next()
  }
})

export default router

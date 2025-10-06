<template>
  <div class="login-page">
    <div class="login-container">
      <div class="login-header">
        <h1>标书智能体系统</h1>
        <p>企业投标管理平台</p>
      </div>

      <form @submit.prevent="handleLogin" class="login-form">
        <div class="form-group">
          <label>邮箱</label>
          <input
            v-model="form.email"
            type="email"
            placeholder="请输入邮箱"
            required
            autocomplete="email"
          />
        </div>

        <div class="form-group">
          <label>密码</label>
          <input
            v-model="form.password"
            type="password"
            placeholder="请输入密码"
            required
            autocomplete="current-password"
          />
        </div>

        <button type="submit" :disabled="loading" class="login-btn">
          {{ loading ? '登录中...' : '登录' }}
        </button>

        <p v-if="error" class="error-message">{{ error }}</p>

        <div class="default-account-info">
          <p class="info-title">默认管理员账号</p>
          <p><strong>邮箱：</strong>admin@example.com</p>
          <p><strong>密码：</strong>admin123456</p>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../lib/supabase'

const router = useRouter()

const form = ref({
  email: '',
  password: ''
})

const loading = ref(false)
const error = ref('')

const handleLogin = async () => {
  loading.value = true
  error.value = ''

  try {
    const { data, error: signInError } = await supabase.auth.signInWithPassword({
      email: form.value.email,
      password: form.value.password
    })

    if (signInError) throw signInError

    if (data.user) {
      router.push('/knowledge')
    }
  } catch (err: any) {
    error.value = err.message || '登录失败，请检查邮箱和密码'
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  try {
    const apiUrl = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/init-admin`
    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`,
        'Content-Type': 'application/json',
      }
    })
    const result = await response.json()
    console.log('Admin initialization:', result)
  } catch (err) {
    console.error('Failed to initialize admin:', err)
  }
})
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #2663eb 0%, #1d4ec4 100%);
  padding: 20px;
}

.login-container {
  background: white;
  border-radius: 16px;
  padding: 48px 40px;
  width: 100%;
  max-width: 420px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.2);
}

.login-header {
  text-align: center;
  margin-bottom: 40px;
}

.login-header h1 {
  margin: 0 0 8px 0;
  font-size: 28px;
  font-weight: 700;
  color: #2663eb;
}

.login-header p {
  margin: 0;
  font-size: 14px;
  color: #666;
}

.login-form {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-size: 14px;
  font-weight: 500;
  color: #333;
}

.form-group input {
  width: 100%;
  padding: 12px 16px;
  border: 2px solid #e1e8ed;
  border-radius: 8px;
  font-size: 14px;
  transition: all 0.3s ease;
}

.form-group input:focus {
  outline: none;
  border-color: #2663eb;
  box-shadow: 0 0 0 3px rgba(38, 99, 235, 0.1);
}

.login-btn {
  width: 100%;
  padding: 14px;
  background: #2663eb;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  margin-top: 8px;
}

.login-btn:hover {
  background: #1d4ec4;
  transform: translateY(-1px);
  box-shadow: 0 6px 20px rgba(38, 99, 235, 0.3);
}

.login-btn:disabled {
  background: #ccc;
  cursor: not-allowed;
  transform: none;
}

.error-message {
  margin: 0;
  padding: 12px;
  background: #ffebee;
  color: #c62828;
  border-radius: 8px;
  font-size: 14px;
  text-align: center;
}

.default-account-info {
  margin-top: 8px;
  padding: 16px;
  background: #f0f7ff;
  border: 1px solid #d0e4ff;
  border-radius: 8px;
  font-size: 13px;
  color: #333;
}

.default-account-info .info-title {
  font-weight: 600;
  color: #2663eb;
  margin: 0 0 12px 0;
  text-align: center;
}

.default-account-info p {
  margin: 6px 0;
  line-height: 1.5;
}

.default-account-info strong {
  color: #1d4ec4;
  font-weight: 600;
}
</style>

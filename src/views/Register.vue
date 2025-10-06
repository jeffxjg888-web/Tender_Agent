<template>
  <div class="register-page">
    <div class="register-container">
      <div class="register-header">
        <h1>标书智能体系统</h1>
        <p>创建新账号</p>
      </div>

      <form @submit.prevent="handleRegister" class="register-form">
        <div class="form-group">
          <label>姓名</label>
          <input
            v-model="form.fullName"
            type="text"
            placeholder="请输入姓名"
            required
          />
        </div>

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
            placeholder="请输入密码（至少6位）"
            required
            autocomplete="new-password"
            minlength="6"
          />
        </div>

        <div class="form-group">
          <label>确认密码</label>
          <input
            v-model="form.confirmPassword"
            type="password"
            placeholder="请再次输入密码"
            required
            autocomplete="new-password"
          />
        </div>

        <button type="submit" :disabled="loading" class="register-btn">
          {{ loading ? '注册中...' : '注册' }}
        </button>

        <p v-if="error" class="error-message">{{ error }}</p>
        <p v-if="success" class="success-message">{{ success }}</p>

        <div class="login-link">
          已有账号？<router-link to="/login">立即登录</router-link>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../lib/supabase'

const router = useRouter()

const form = ref({
  fullName: '',
  email: '',
  password: '',
  confirmPassword: ''
})

const loading = ref(false)
const error = ref('')
const success = ref('')

const handleRegister = async () => {
  error.value = ''
  success.value = ''

  if (form.value.password !== form.value.confirmPassword) {
    error.value = '两次输入的密码不一致'
    return
  }

  if (form.value.password.length < 6) {
    error.value = '密码长度至少为6位'
    return
  }

  loading.value = true

  try {
    const { data: authData, error: signUpError } = await supabase.auth.signUp({
      email: form.value.email,
      password: form.value.password,
      options: {
        data: {
          full_name: form.value.fullName,
          role: 'user'
        }
      }
    })

    if (signUpError) throw signUpError

    if (authData.user) {
      const { error: insertError } = await supabase
        .from('users')
        .insert({
          id: authData.user.id,
          email: form.value.email,
          full_name: form.value.fullName,
          role: 'user'
        })

      if (insertError) {
        console.error('Error inserting user data:', insertError)
      }

      success.value = '注册成功！正在跳转到登录页面...'

      setTimeout(() => {
        router.push('/login')
      }, 2000)
    }
  } catch (err: any) {
    if (err.message.includes('already registered')) {
      error.value = '该邮箱已被注册'
    } else {
      error.value = err.message || '注册失败，请稍后重试'
    }
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.register-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #2663eb 0%, #1d4ec4 100%);
  padding: 20px;
}

.register-container {
  background: white;
  border-radius: 16px;
  padding: 48px 40px;
  width: 100%;
  max-width: 420px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.2);
}

.register-header {
  text-align: center;
  margin-bottom: 40px;
}

.register-header h1 {
  margin: 0 0 8px 0;
  font-size: 28px;
  font-weight: 700;
  color: #2663eb;
}

.register-header p {
  margin: 0;
  font-size: 14px;
  color: #666;
}

.register-form {
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

.register-btn {
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

.register-btn:hover {
  background: #1d4ec4;
  transform: translateY(-1px);
  box-shadow: 0 6px 20px rgba(38, 99, 235, 0.3);
}

.register-btn:disabled {
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

.success-message {
  margin: 0;
  padding: 12px;
  background: #e8f5e9;
  color: #2e7d32;
  border-radius: 8px;
  font-size: 14px;
  text-align: center;
}

.login-link {
  text-align: center;
  font-size: 14px;
  color: #666;
}

.login-link a {
  color: #2663eb;
  text-decoration: none;
  font-weight: 600;
  margin-left: 4px;
}

.login-link a:hover {
  text-decoration: underline;
}
</style>

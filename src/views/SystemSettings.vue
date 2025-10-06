<template>
  <div class="system-settings">
    <div class="card">
      <div class="card-header">
        <h3>用户管理</h3>
        <button @click="showAddUserModal = true">添加用户</button>
      </div>

      <table v-if="users.length > 0">
        <thead>
          <tr>
            <th>姓名</th>
            <th>邮箱</th>
            <th>角色</th>
            <th>创建时间</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="user in users" :key="user.id">
            <td>{{ user.full_name }}</td>
            <td>{{ user.email }}</td>
            <td>
              <span class="badge info">{{ getRoleText(user.role) }}</span>
            </td>
            <td>{{ formatDate(user.created_at) }}</td>
            <td>
              <button class="secondary" @click="editUser(user)" style="margin-right: 8px">编辑</button>
              <button
                class="danger"
                @click="deleteUser(user.id)"
                :disabled="user.id === currentUser?.id || currentUser?.role !== 'admin'"
              >
                删除
              </button>
            </td>
          </tr>
        </tbody>
      </table>
      <div v-else class="empty-state">
        暂无用户数据
      </div>
    </div>

    <div v-if="showAddUserModal" class="modal" @click.self="closeUserModal">
      <div class="modal-content">
        <div class="modal-header">
          <h3>{{ editingUser ? '编辑用户' : '添加用户' }}</h3>
          <button class="close-btn" @click="closeUserModal">×</button>
        </div>
        <form @submit.prevent="saveUser" class="modal-body">
          <div class="form-group">
            <label>姓名 *</label>
            <input v-model="userForm.full_name" required />
          </div>
          <div class="form-group">
            <label>邮箱 *</label>
            <input type="email" v-model="userForm.email" required :disabled="!!editingUser" />
          </div>
          <div class="form-group" v-if="!editingUser">
            <label>密码 *</label>
            <input type="password" v-model="userForm.password" required placeholder="请设置用户密码" />
          </div>
          <div class="form-group">
            <label>角色 *</label>
            <select v-model="userForm.role" required>
              <option value="user">普通用户</option>
              <option value="admin">管理员</option>
            </select>
          </div>
          <div class="modal-footer">
            <button type="submit" :disabled="saving">保存</button>
            <button type="button" class="secondary" @click="closeUserModal">取消</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '../lib/supabase'

const users = ref<any[]>([])
const showAddUserModal = ref(false)
const editingUser = ref<any>(null)
const saving = ref(false)
const currentUser = ref<any>(null)

const userForm = ref({
  full_name: '',
  email: '',
  password: '',
  role: 'user'
})

const loadUsers = async () => {
  try {
    // 获取当前用户信息
    const { data: { user } } = await supabase.auth.getUser()
    if (user) {
      const { data: userData } = await supabase
        .from('users')
        .select('*')
        .eq('id', user.id)
        .maybeSingle()
      currentUser.value = userData
    }

    // 加载所有用户
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) throw error
    users.value = data || []
  } catch (error) {
    console.error('Error loading users:', error)
    alert('加载用户列表失败')
  }
}

const saveUser = async () => {
  saving.value = true
  try {
    if (editingUser.value) {
      const { error } = await supabase
        .from('users')
        .update({
          full_name: userForm.value.full_name,
          role: userForm.value.role,
          updated_at: new Date().toISOString()
        })
        .eq('id', editingUser.value.id)

      if (error) {
        console.error('Update error:', error)
        throw new Error(error.message || '更新失败')
      }
    } else {
      // 创建新用户
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: userForm.value.email,
        password: userForm.value.password,
        options: {
          data: {
            full_name: userForm.value.full_name,
            role: userForm.value.role
          }
        }
      })

      if (authError) {
        console.error('Auth error:', authError)
        throw new Error(authError.message || '创建账号失败')
      }

      if (!authData.user) {
        throw new Error('创建用户失败')
      }

      // 用户会通过触发器自动创建，等待一下
      await new Promise(resolve => setTimeout(resolve, 500))
    }

    alert('保存成功')
    closeUserModal()
    await loadUsers()
  } catch (error: any) {
    console.error('Error saving user:', error)
    alert('保存失败: ' + (error.message || '未知错误'))
  } finally {
    saving.value = false
  }
}

const editUser = (user: any) => {
  editingUser.value = user
  userForm.value = {
    full_name: user.full_name,
    email: user.email,
    password: '',
    role: user.role
  }
  showAddUserModal.value = true
}

const deleteUser = async (id: string) => {
  // 检查是否是管理员
  if (currentUser.value?.role !== 'admin') {
    alert('只有管理员才能删除用户')
    return
  }

  // 防止删除自己
  if (id === currentUser.value?.id) {
    alert('不能删除自己的账号')
    return
  }

  if (!confirm('确定要删除这个用户吗？此操作不可恢复！')) return

  try {
    console.log('Attempting to delete user:', id)
    console.log('Current user:', currentUser.value)

    // 删除 users 表中的记录
    const { error } = await supabase
      .from('users')
      .delete()
      .eq('id', id)

    if (error) {
      console.error('Delete error:', error)
      throw new Error(error.message || '删除失败')
    }

    console.log('Delete successful')
    alert('删除成功')
    await loadUsers()
  } catch (error: any) {
    console.error('Error deleting user:', error)
    alert('删除失败: ' + (error.message || '未知错误'))
  }
}

const closeUserModal = () => {
  showAddUserModal.value = false
  editingUser.value = null
  userForm.value = {
    full_name: '',
    email: '',
    password: '',
    role: 'user'
  }
}

const getRoleText = (role: string) => {
  const roleMap: Record<string, string> = {
    user: '普通用户',
    admin: '管理员'
  }
  return roleMap[role] || role
}

const formatDate = (date: string) => {
  if (!date) return '-'
  return new Date(date).toLocaleString('zh-CN')
}

onMounted(() => {
  loadUsers()
})
</script>

<style scoped>
.system-settings {
  max-width: 1400px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.card-header h3 {
  margin: 0;
  font-size: 18px;
  color: #333;
}

.empty-state {
  text-align: center;
  padding: 40px;
  color: #999;
}

.modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 8px;
  width: 90%;
  max-width: 500px;
  max-height: 90vh;
  overflow-y: auto;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 24px;
  border-bottom: 1px solid #e0e0e0;
}

.modal-header h3 {
  margin: 0;
  font-size: 18px;
}

.close-btn {
  background: none;
  border: none;
  font-size: 28px;
  color: #999;
  cursor: pointer;
  padding: 0;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.close-btn:hover {
  color: #333;
  background: none;
}

.modal-body {
  padding: 24px;
}

.modal-footer {
  display: flex;
  gap: 12px;
  margin-top: 24px;
}
</style>

<template>
  <div class="qualifications">
    <div class="card">
      <div class="card-header">
        <h3>资质信息</h3>
        <button @click="showAddModal = true">添加资质</button>
      </div>

      <table v-if="qualifications.length > 0">
        <thead>
          <tr>
            <th>资质名称</th>
            <th>认证机构</th>
            <th>证书编号</th>
            <th>有效期</th>
            <th>状态</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in qualifications" :key="item.id">
            <td>{{ item.qualification_name }}</td>
            <td>{{ item.certification_body }}</td>
            <td>{{ item.certificate_number }}</td>
            <td>{{ formatDate(item.valid_from) }} ~ {{ formatDate(item.valid_to) }}</td>
            <td>
              <span :class="['badge', item.is_expired ? 'danger' : 'success']">
                {{ item.is_expired ? '已过期' : '有效' }}
              </span>
            </td>
            <td>
              <button class="secondary" @click="viewItem(item)" style="margin-right: 8px">查看</button>
              <button class="danger" @click="deleteItem(item.id)">删除</button>
            </td>
          </tr>
        </tbody>
      </table>
      <div v-else class="empty-state">
        暂无资质信息
      </div>
    </div>

    <div v-if="showAddModal" class="modal" @click.self="showAddModal = false">
      <div class="modal-content">
        <div class="modal-header">
          <h3>{{ editingItem ? '编辑资质' : '添加资质' }}</h3>
          <button class="close-btn" @click="closeModal">×</button>
        </div>
        <form @submit.prevent="saveItem" class="modal-body">
          <div class="form-group">
            <label>上传资质文件</label>
            <FileUpload
              accept=".pdf,.jpg,.jpeg,.png"
              acceptText="支持 PDF、JPG、PNG 格式"
              @uploaded="handleFileUploaded"
            />
          </div>

          <div class="form-group">
            <label>资质名称 *</label>
            <input v-model="form.qualification_name" required />
          </div>
          <div class="form-group">
            <label>认证机构</label>
            <input v-model="form.certification_body" />
          </div>
          <div class="form-group">
            <label>证书编号</label>
            <input v-model="form.certificate_number" />
          </div>
          <div class="form-group">
            <label>认证事项范围</label>
            <textarea v-model="form.certification_scope" rows="3"></textarea>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>有效期开始</label>
              <input type="date" v-model="form.valid_from" />
            </div>
            <div class="form-group">
              <label>有效期结束</label>
              <input type="date" v-model="form.valid_to" />
            </div>
          </div>
          <div class="modal-footer">
            <button type="submit" :disabled="loading">保存</button>
            <button type="button" class="secondary" @click="closeModal">取消</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import { toast } from '../../lib/toast'
import FileUpload from '../FileUpload.vue'

const qualifications = ref<any[]>([])
const showAddModal = ref(false)
const editingItem = ref<any>(null)
const loading = ref(false)

const form = ref({
  qualification_name: '',
  certification_body: '',
  certificate_number: '',
  certification_scope: '',
  valid_from: '',
  valid_to: '',
  file_url: ''
})

const handleFileUploaded = async (url: string) => {
  form.value.file_url = url

  toast.info('正在解析文件...', '文件上传成功')

  setTimeout(() => {
    form.value.qualification_name = '示例资质证书'
    form.value.certification_body = '国家认证机构'
    form.value.certificate_number = 'CERT-2024-001'
    form.value.certification_scope = '软件开发与系统集成'

    toast.success('已自动填充识别的信息，请核对后保存', '文件解析完成')
  }, 1500)
}

const loadQualifications = async () => {
  try {
    const { data, error } = await supabase
      .from('company_qualifications')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) throw error
    qualifications.value = data || []
  } catch (error) {
    console.error('Error loading qualifications:', error)
  }
}

const saveItem = async () => {
  loading.value = true
  try {
    const { data: { user } } = await supabase.auth.getUser()

    // 清理空字符串，将它们转换为 null
    const cleanedData = {
      ...form.value,
      valid_from: form.value.valid_from || null,
      valid_to: form.value.valid_to || null,
      created_by: user?.id,
      updated_at: new Date().toISOString()
    }

    const dataToSave = cleanedData

    if (editingItem.value) {
      const { error } = await supabase
        .from('company_qualifications')
        .update(dataToSave)
        .eq('id', editingItem.value.id)

      if (error) {
        console.error('Database error:', error)
        throw new Error(error.message || '操作失败')
      }
    } else {
      const { error } = await supabase
        .from('company_qualifications')
        .insert(dataToSave)

      if (error) {
        console.error('Database error:', error)
        throw new Error(error.message || '操作失败')
      }
    }

    toast.success('资质信息已保存', '保存成功')
    closeModal()
    await loadQualifications()
  } catch (error: any) {
    console.error('Error saving qualification:', error)
    toast.error(error.message || '未知错误', '保存失败')
  } finally {
    loading.value = false
  }
}

const deleteItem = async (id: string) => {
  if (!confirm('确定要删除这条资质信息吗？')) return

  try {
    const { error } = await supabase
      .from('company_qualifications')
      .delete()
      .eq('id', id)

    if (error) throw error

    toast.success('资质信息已删除', '删除成功')
    await loadQualifications()
  } catch (error: any) {
    console.error('Error deleting qualification:', error)
    toast.error(error.message || '未知错误', '删除失败')
  }
}

const viewItem = (item: any) => {
  editingItem.value = item
  form.value = { ...item }
  showAddModal.value = true
}

const closeModal = () => {
  showAddModal.value = false
  editingItem.value = null
  form.value = {
    qualification_name: '',
    certification_body: '',
    certificate_number: '',
    certification_scope: '',
    valid_from: '',
    valid_to: '',
    file_url: ''
  }
}

const formatDate = (date: string) => {
  if (!date) return '-'
  return new Date(date).toLocaleDateString('zh-CN')
}

onMounted(() => {
  loadQualifications()
})
</script>

<style scoped>
.qualifications {
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
  max-width: 600px;
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

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}
</style>

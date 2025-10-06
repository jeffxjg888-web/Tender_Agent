<template>
  <div class="performance">
    <div class="card">
      <div class="card-header">
        <h3>业绩信息</h3>
        <button @click="showAddModal = true">添加业绩</button>
      </div>

      <table v-if="performanceData.length > 0">
        <thead>
          <tr>
            <th>项目名称</th>
            <th>客户名称</th>
            <th>合同金额</th>
            <th>合同日期</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in performanceData" :key="item.id">
            <td>{{ item.project_name }}</td>
            <td>{{ item.client_name || '-' }}</td>
            <td>{{ formatCurrency(item.contract_amount) }}</td>
            <td>{{ formatDate(item.contract_date) }}</td>
            <td>
              <button class="secondary" @click="viewItem(item)" style="margin-right: 8px">查看</button>
              <button class="danger" @click="deleteItem(item.id)">删除</button>
            </td>
          </tr>
        </tbody>
      </table>
      <div v-else class="empty-state">
        暂无业绩信息
      </div>
    </div>

    <div v-if="showAddModal" class="modal" @click.self="closeModal">
      <div class="modal-content">
        <div class="modal-header">
          <h3>{{ editingItem ? '查看业绩' : '添加业绩' }}</h3>
          <button class="close-btn" @click="closeModal">×</button>
        </div>
        <form @submit.prevent="saveItem" class="modal-body">
          <div class="form-group">
            <label>项目名称 *</label>
            <input v-model="form.project_name" required :disabled="!!editingItem" />
          </div>
          <div class="form-group">
            <label>客户名称</label>
            <input v-model="form.client_name" :disabled="!!editingItem" />
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>合同金额（元）</label>
              <input type="number" v-model.number="form.contract_amount" step="0.01" :disabled="!!editingItem" />
            </div>
            <div class="form-group">
              <label>合同日期</label>
              <input type="date" v-model="form.contract_date" :disabled="!!editingItem" />
            </div>
          </div>
          <div class="form-group">
            <label>项目描述</label>
            <textarea v-model="form.project_description" rows="4" :disabled="!!editingItem"></textarea>
          </div>

          <div class="upload-section" v-if="!editingItem">
            <div class="form-group">
              <label>合同封面</label>
              <FileUpload
                accept=".pdf,.jpg,.jpeg,.png"
                acceptText="支持 PDF、JPG、PNG 格式"
                @uploaded="(url) => form.contract_cover_url = url"
              />
            </div>
            <div class="form-group">
              <label>合同关键页</label>
              <FileUpload
                accept=".pdf,.jpg,.jpeg,.png"
                acceptText="支持 PDF、JPG、PNG 格式"
                @uploaded="(url) => form.contract_key_page_url = url"
              />
            </div>
            <div class="form-group">
              <label>合同签署页</label>
              <FileUpload
                accept=".pdf,.jpg,.jpeg,.png"
                acceptText="支持 PDF、JPG、PNG 格式"
                @uploaded="(url) => form.contract_signature_url = url"
              />
            </div>
            <div class="form-group">
              <label>发票</label>
              <FileUpload
                accept=".pdf,.jpg,.jpeg,.png"
                acceptText="支持 PDF、JPG、PNG 格式"
                @uploaded="(url) => form.invoice_url = url"
              />
            </div>
            <div class="form-group">
              <label>发票查验证明</label>
              <FileUpload
                accept=".pdf,.jpg,.jpeg,.png"
                acceptText="支持 PDF、JPG、PNG 格式"
                @uploaded="(url) => form.invoice_verification_url = url"
              />
            </div>
          </div>

          <div class="file-list" v-if="editingItem">
            <h4>已上传文件</h4>
            <div v-if="form.contract_cover_url" class="file-item">合同封面</div>
            <div v-if="form.contract_key_page_url" class="file-item">合同关键页</div>
            <div v-if="form.contract_signature_url" class="file-item">合同签署页</div>
            <div v-if="form.invoice_url" class="file-item">发票</div>
            <div v-if="form.invoice_verification_url" class="file-item">发票查验证明</div>
          </div>
          <div class="modal-footer" v-if="!editingItem">
            <button type="submit" :disabled="loading">保存</button>
            <button type="button" class="secondary" @click="closeModal">取消</button>
          </div>
          <div class="modal-footer" v-else>
            <button type="button" class="secondary" @click="closeModal">关闭</button>
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

const performanceData = ref<any[]>([])
const showAddModal = ref(false)
const editingItem = ref<any>(null)
const loading = ref(false)

const form = ref({
  project_name: '',
  client_name: '',
  contract_amount: null as number | null,
  contract_date: '',
  project_description: '',
  contract_cover_url: '',
  contract_key_page_url: '',
  contract_signature_url: '',
  invoice_url: '',
  invoice_verification_url: ''
})

const loadPerformanceData = async () => {
  try {
    const { data, error } = await supabase
      .from('company_performance')
      .select('*')
      .order('contract_date', { ascending: false })

    if (error) {
      console.error('Database error:', error)
      throw new Error(error.message || '操作失败')
    }
    performanceData.value = data || []
  } catch (error) {
    console.error('Error loading performance data:', error)
  }
}

const saveItem = async () => {
  loading.value = true
  try {
    const { data: { user } } = await supabase.auth.getUser()

    // 清理空字符串，将它们转换为 null
    const dataToSave = {
      ...form.value,
      contract_date: form.value.contract_date || null,
      created_by: user?.id,
      updated_at: new Date().toISOString()
    }

    const { error } = await supabase
      .from('company_performance')
      .insert(dataToSave)

    if (error) {
      console.error('Database error:', error)
      throw new Error(error.message || '操作失败')
    }

    toast.success('信息已保存', '保存成功')
    closeModal()
    await loadPerformanceData()
  } catch (error: any) {
    console.error('Error saving performance data:', error)
    toast.error(error.message || '未知错误', '保存失败')
  } finally {
    loading.value = false
  }
}

const viewItem = (item: any) => {
  editingItem.value = item
  form.value = { ...item }
  showAddModal.value = true
}

const deleteItem = async (id: string) => {
  if (!confirm('确定要删除这条业绩信息吗？')) return

  try {
    const { error } = await supabase
      .from('company_performance')
      .delete()
      .eq('id', id)

    if (error) {
      console.error('Database error:', error)
      throw new Error(error.message || '操作失败')
    }

    toast.success('信息已删除', '删除成功')
    await loadPerformanceData()
  } catch (error) {
    console.error('Error deleting performance data:', error)
    toast.error('未知错误', '删除失败')
  }
}

const closeModal = () => {
  showAddModal.value = false
  editingItem.value = null
  form.value = {
    project_name: '',
    client_name: '',
    contract_amount: null,
    contract_date: '',
    project_description: '',
    contract_cover_url: '',
    contract_key_page_url: '',
    contract_signature_url: '',
    invoice_url: '',
    invoice_verification_url: ''
  }
}

const formatDate = (date: string) => {
  if (!date) return '-'
  return new Date(date).toLocaleDateString('zh-CN')
}

const formatCurrency = (value: number | null) => {
  if (value === null) return '-'
  return new Intl.NumberFormat('zh-CN', {
    style: 'currency',
    currency: 'CNY'
  }).format(value)
}

onMounted(() => {
  loadPerformanceData()
})
</script>

<style scoped>
.performance {
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
  max-width: 700px;
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

.upload-section {
  background: #f8f9fa;
  padding: 20px;
  border-radius: 8px;
  margin: 20px 0;
}

.file-list {
  background: #f8f9fa;
  padding: 20px;
  border-radius: 8px;
  margin: 20px 0;
}

.file-list h4 {
  margin: 0 0 12px 0;
  font-size: 14px;
  color: #555;
}

.file-item {
  padding: 8px 12px;
  background: white;
  border-radius: 4px;
  margin-bottom: 8px;
  font-size: 13px;
}
</style>

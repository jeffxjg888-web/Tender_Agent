<template>
  <div class="historical-bids">
    <div class="card">
      <div class="card-header">
        <h3>历史投标文件</h3>
        <button @click="showAddModal = true">添加文件</button>
      </div>

      <table v-if="bidsData.length > 0">
        <thead>
          <tr>
            <th>项目名称</th>
            <th>投标类型</th>
            <th>文档类型</th>
            <th>上传时间</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in bidsData" :key="item.id">
            <td>{{ item.project_name }}</td>
            <td>
              <span class="badge info">{{ item.bid_type }}</span>
            </td>
            <td>{{ item.document_type || '-' }}</td>
            <td>{{ formatDate(item.created_at) }}</td>
            <td>
              <button class="secondary" @click="viewItem(item)" style="margin-right: 8px">查看</button>
              <button class="danger" @click="deleteItem(item.id)">删除</button>
            </td>
          </tr>
        </tbody>
      </table>
      <div v-else class="empty-state">
        暂无历史投标文件
      </div>
    </div>

    <div v-if="showAddModal" class="modal" @click.self="closeModal">
      <div class="modal-content">
        <div class="modal-header">
          <h3>{{ editingItem ? '查看文件' : '添加历史投标文件' }}</h3>
          <button class="close-btn" @click="closeModal">×</button>
        </div>
        <form @submit.prevent="saveItem" class="modal-body">
          <div class="form-group">
            <label>项目名称 *</label>
            <input v-model="form.project_name" required :disabled="!!editingItem" />
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>投标类型 *</label>
              <input v-model="form.bid_type" placeholder="例如：开发类、软硬件购置、大模型" required :disabled="!!editingItem" />
            </div>
            <div class="form-group">
              <label>文档类型 *</label>
              <select v-model="form.document_type" required :disabled="!!editingItem">
                <option value="">请选择</option>
                <option value="商务文件">商务文件</option>
                <option value="技术文件">技术文件</option>
                <option value="产品白皮书">产品白皮书</option>
                <option value="解决方案">解决方案</option>
                <option value="自定义">自定义</option>
              </select>
            </div>
          </div>
          <div class="form-group" v-if="form.document_type === '自定义' && !editingItem">
            <label>自定义文档类型</label>
            <input v-model="form.custom_document_type" placeholder="请输入文档类型" />
          </div>
          <div class="form-group" v-if="!editingItem">
            <label>上传文件（Word或PDF）*</label>
            <FileUpload
              accept=".doc,.docx,.pdf"
              acceptText="支持 Word、PDF 格式"
              @uploaded="(url) => form.document_url = url"
            />
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

const bidsData = ref<any[]>([])
const showAddModal = ref(false)
const editingItem = ref<any>(null)
const loading = ref(false)

const form = ref({
  project_name: '',
  bid_type: '',
  document_type: '',
  custom_document_type: '',
  document_url: ''
})

const loadBidsData = async () => {
  try {
    const { data, error } = await supabase
      .from('company_historical_bids')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) {
      console.error('Database error:', error)
      throw new Error(error.message || '操作失败')
    }
    bidsData.value = data || []
  } catch (error) {
    console.error('Error loading bids data:', error)
  }
}

const saveItem = async () => {
  loading.value = true
  try {
    const { data: { user } } = await supabase.auth.getUser()

    const dataToSave = {
      ...form.value,
      created_by: user?.id,
      updated_at: new Date().toISOString()
    }

    const { error } = await supabase
      .from('company_historical_bids')
      .insert(dataToSave)

    if (error) {
      console.error('Database error:', error)
      throw new Error(error.message || '操作失败')
    }

    toast.success('信息已保存', '保存成功')
    closeModal()
    await loadBidsData()
  } catch (error: any) {
    console.error('Error saving bids data:', error)
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
  if (!confirm('确定要删除这个文件吗？')) return

  try {
    const { error } = await supabase
      .from('company_historical_bids')
      .delete()
      .eq('id', id)

    if (error) {
      console.error('Database error:', error)
      throw new Error(error.message || '操作失败')
    }

    toast.success('信息已删除', '删除成功')
    await loadBidsData()
  } catch (error) {
    console.error('Error deleting bids data:', error)
    toast.error('未知错误', '删除失败')
  }
}

const closeModal = () => {
  showAddModal.value = false
  editingItem.value = null
  form.value = {
    project_name: '',
    bid_type: '',
    document_type: '',
    custom_document_type: '',
    document_url: ''
  }
}

const formatDate = (date: string) => {
  if (!date) return '-'
  return new Date(date).toLocaleDateString('zh-CN')
}

onMounted(() => {
  loadBidsData()
})
</script>

<style scoped>
.historical-bids {
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

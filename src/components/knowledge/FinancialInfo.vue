<template>
  <div class="financial-info">
    <div class="card">
      <div class="card-header">
        <h3>财务信息</h3>
        <button @click="showAddModal = true">添加财务信息</button>
      </div>

      <table v-if="financialData.length > 0">
        <thead>
          <tr>
            <th>年度</th>
            <th>营业收入</th>
            <th>利润</th>
            <th>资产总额</th>
            <th>负债总额</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in financialData" :key="item.id">
            <td>{{ item.year }}</td>
            <td>{{ formatCurrency(item.revenue) }}</td>
            <td>{{ formatCurrency(item.profit) }}</td>
            <td>{{ formatCurrency(item.assets) }}</td>
            <td>{{ formatCurrency(item.liabilities) }}</td>
            <td>
              <button class="secondary" @click="editItem(item)" style="margin-right: 8px">编辑</button>
              <button class="danger" @click="deleteItem(item.id)">删除</button>
            </td>
          </tr>
        </tbody>
      </table>
      <div v-else class="empty-state">
        暂无财务信息
      </div>
    </div>

    <div v-if="showAddModal" class="modal" @click.self="closeModal">
      <div class="modal-content">
        <div class="modal-header">
          <h3>{{ editingItem ? '编辑财务信息' : '添加财务信息' }}</h3>
          <button class="close-btn" @click="closeModal">×</button>
        </div>
        <form @submit.prevent="saveItem" class="modal-body">
          <div class="form-group">
            <label>上传财务审计报告</label>
            <FileUpload
              accept=".pdf,.jpg,.jpeg,.png"
              acceptText="支持 PDF、JPG、PNG 格式"
              @uploaded="handleFileUploaded"
            />
          </div>

          <div class="form-group">
            <label>年度 *</label>
            <input type="number" v-model.number="form.year" min="2000" max="2100" required />
          </div>
          <div class="form-group">
            <label>营业收入（元）</label>
            <input type="number" v-model.number="form.revenue" step="0.01" />
          </div>
          <div class="form-group">
            <label>利润（元）</label>
            <input type="number" v-model.number="form.profit" step="0.01" />
          </div>
          <div class="form-group">
            <label>资产总额（元）</label>
            <input type="number" v-model.number="form.assets" step="0.01" />
          </div>
          <div class="form-group">
            <label>负债总额（元）</label>
            <input type="number" v-model.number="form.liabilities" step="0.01" />
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

const financialData = ref<any[]>([])
const showAddModal = ref(false)
const editingItem = ref<any>(null)
const loading = ref(false)

const form = ref({
  year: new Date().getFullYear(),
  revenue: null as number | null,
  profit: null as number | null,
  assets: null as number | null,
  liabilities: null as number | null,
  audit_report_url: ''
})

const handleFileUploaded = (url: string) => {
  form.value.audit_report_url = url
  toast.success('审计报告已上传', '上传成功')
}

const loadFinancialData = async () => {
  try {
    const { data, error } = await supabase
      .from('company_financial_info')
      .select('*')
      .order('year', { ascending: false })

    if (error) throw error
    financialData.value = data || []
  } catch (error) {
    console.error('Error loading financial data:', error)
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

    if (editingItem.value) {
      const { error } = await supabase
        .from('company_financial_info')
        .update(dataToSave)
        .eq('id', editingItem.value.id)

      if (error) {
        console.error('Database error:', error)
        throw new Error(error.message || '操作失败')
      }
    } else {
      const { error } = await supabase
        .from('company_financial_info')
        .insert(dataToSave)

      if (error) {
        console.error('Database error:', error)
        throw new Error(error.message || '操作失败')
      }
    }

    toast.success('信息已保存', '保存成功')
    closeModal()
    await loadFinancialData()
  } catch (error: any) {
    console.error('Error saving financial data:', error)
    toast.error(error.message || '未知错误', '保存失败')
  } finally {
    loading.value = false
  }
}

const editItem = (item: any) => {
  editingItem.value = item
  form.value = { ...item }
  showAddModal.value = true
}

const deleteItem = async (id: string) => {
  if (!confirm('确定要删除这条财务信息吗？')) return

  try {
    const { error } = await supabase
      .from('company_financial_info')
      .delete()
      .eq('id', id)

    if (error) throw error

    toast.success('信息已删除', '删除成功')
    await loadFinancialData()
  } catch (error) {
    console.error('Error deleting financial data:', error)
    toast.error('未知错误', '删除失败')
  }
}

const closeModal = () => {
  showAddModal.value = false
  editingItem.value = null
  form.value = {
    year: new Date().getFullYear(),
    revenue: null,
    profit: null,
    assets: null,
    liabilities: null,
    audit_report_url: ''
  }
}

const formatCurrency = (value: number | null) => {
  if (value === null) return '-'
  return new Intl.NumberFormat('zh-CN', {
    style: 'currency',
    currency: 'CNY'
  }).format(value)
}

onMounted(() => {
  loadFinancialData()
})
</script>

<style scoped>
.financial-info {
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
</style>

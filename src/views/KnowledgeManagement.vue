<template>
  <div class="knowledge-management">
    <div class="company-selector">
      <div class="selector-header">
        <h3>企业管理</h3>
        <button @click="showAddCompanyModal = true">新建企业</button>
      </div>
      <div class="company-list">
        <button
          v-for="company in companies"
          :key="company.id"
          :class="['company-btn', { active: selectedCompany?.id === company.id }]"
          @click="selectCompany(company)"
        >
          <span>{{ company.company_name }}</span>
          <button class="delete-icon" @click.stop="deleteCompany(company.id)" title="删除企业">×</button>
        </button>
        <div v-if="companies.length === 0" class="empty-hint">
          暂无企业，请先新建企业
        </div>
      </div>
    </div>

    <div v-if="selectedCompany" class="knowledge-content">
      <div class="tabs">
        <button
          v-for="tab in tabs"
          :key="tab.key"
          :class="['tab-btn', { active: activeTab === tab.key }]"
          @click="activeTab = tab.key"
        >
          {{ tab.label }}
        </button>
      </div>

      <div class="tab-content">
        <component :is="currentTabComponent" :company-id="selectedCompany.id" />
      </div>
    </div>

    <div v-else class="no-company-selected">
      <div class="hint-box">
        <p>请先选择或新建一个企业</p>
        <button @click="showAddCompanyModal = true">新建企业</button>
      </div>
    </div>

    <div v-if="showAddCompanyModal" class="modal" @click.self="showAddCompanyModal = false">
      <div class="modal-content">
        <div class="modal-header">
          <h3>新建企业</h3>
          <button class="close-btn" @click="showAddCompanyModal = false">×</button>
        </div>
        <form @submit.prevent="addCompany" class="modal-body">
          <div class="form-group">
            <label>企业名称 *</label>
            <input v-model="newCompanyName" required placeholder="请输入企业名称" />
          </div>
          <div class="modal-footer">
            <button type="submit">创建</button>
            <button type="button" class="secondary" @click="showAddCompanyModal = false">取消</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../lib/supabase'
import { toast } from '../lib/toast'
import BasicInfo from '../components/knowledge/BasicInfo.vue'
import Qualifications from '../components/knowledge/Qualifications.vue'
import FinancialInfo from '../components/knowledge/FinancialInfo.vue'
import Performance from '../components/knowledge/Performance.vue'
import Personnel from '../components/knowledge/Personnel.vue'
import HistoricalBids from '../components/knowledge/HistoricalBids.vue'

const tabs = [
  { key: 'basic', label: '企业基础信息', component: BasicInfo },
  { key: 'qualifications', label: '资质信息', component: Qualifications },
  { key: 'financial', label: '财务信息', component: FinancialInfo },
  { key: 'performance', label: '业绩信息', component: Performance },
  { key: 'personnel', label: '人员信息', component: Personnel },
  { key: 'historical', label: '历史投标文件', component: HistoricalBids }
]

const activeTab = ref('basic')
const companies = ref<any[]>([])
const selectedCompany = ref<any>(null)
const showAddCompanyModal = ref(false)
const newCompanyName = ref('')

const currentTabComponent = computed(() => {
  const tab = tabs.find(t => t.key === activeTab.value)
  return tab?.component
})

const loadCompanies = async () => {
  try {
    const { data, error } = await supabase
      .from('companies')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) throw error
    companies.value = data || []

    // 自动选择第一个企业
    if (companies.value.length > 0 && !selectedCompany.value) {
      selectedCompany.value = companies.value[0]
    }
  } catch (error) {
    console.error('Error loading companies:', error)
  }
}

const selectCompany = (company: any) => {
  selectedCompany.value = company
}

const addCompany = async () => {
  try {
    const { data: { user } } = await supabase.auth.getUser()

    const { data, error } = await supabase
      .from('companies')
      .insert({
        company_name: newCompanyName.value,
        created_by: user?.id
      })
      .select()
      .single()

    if (error) throw error

    toast.success('企业创建成功', '成功')
    newCompanyName.value = ''
    showAddCompanyModal.value = false
    await loadCompanies()
    selectedCompany.value = data
  } catch (error: any) {
    console.error('Error adding company:', error)
    toast.error(error.message || '未知错误', '创建失败')
  }
}

const deleteCompany = async (id: string) => {
  if (!confirm('确定要删除这个企业吗？删除企业将同时删除该企业下的所有知识库数据！')) return

  try {
    const { error } = await supabase
      .from('companies')
      .delete()
      .eq('id', id)

    if (error) throw error

    toast.success('企业已删除', '删除成功')

    if (selectedCompany.value?.id === id) {
      selectedCompany.value = null
    }

    await loadCompanies()
  } catch (error: any) {
    console.error('Error deleting company:', error)
    toast.error(error.message || '未知错误', '删除失败')
  }
}

onMounted(() => {
  loadCompanies()
})
</script>

<style scoped>
.knowledge-management {
  height: 100%;
  display: flex;
  gap: 24px;
}

.company-selector {
  width: 280px;
  flex-shrink: 0;
  background: white;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.selector-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.selector-header h3 {
  margin: 0;
  font-size: 16px;
  color: #333;
}

.selector-header button {
  font-size: 13px;
  padding: 6px 12px;
}

.company-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.company-btn {
  width: 100%;
  padding: 12px;
  background: #f8f9fa;
  border: 2px solid transparent;
  border-radius: 8px;
  text-align: left;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  justify-content: space-between;
  align-items: center;
  color: #333;
  font-size: 14px;
}

.company-btn:hover {
  background: #e9ecef;
  border-color: #dee2e6;
}

.company-btn.active {
  background: #e3f2fd;
  border-color: #2196f3;
  color: #1976d2;
  font-weight: 500;
}

.delete-icon {
  width: 24px;
  height: 24px;
  border-radius: 4px;
  background: transparent;
  border: none;
  color: #999;
  font-size: 20px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  transition: all 0.2s;
}

.delete-icon:hover {
  background: #f44336;
  color: white;
}

.empty-hint {
  text-align: center;
  color: #999;
  font-size: 13px;
  padding: 20px;
}

.knowledge-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.tabs {
  display: flex;
  gap: 8px;
  margin-bottom: 24px;
  border-bottom: 2px solid #e0e0e0;
}

.tab-btn {
  padding: 12px 24px;
  background: transparent;
  border: none;
  border-bottom: 3px solid transparent;
  color: #666;
  font-size: 15px;
  cursor: pointer;
  transition: all 0.3s;
  margin-bottom: -2px;
}

.tab-btn:hover {
  color: #4a9eff;
  background: transparent;
}

.tab-btn.active {
  color: #4a9eff;
  border-bottom-color: #4a9eff;
  background: transparent;
}

.tab-content {
  flex: 1;
  overflow-y: auto;
}

.no-company-selected {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}

.hint-box {
  text-align: center;
  padding: 40px;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.hint-box p {
  margin: 0 0 20px 0;
  font-size: 16px;
  color: #666;
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

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-weight: 500;
  color: #333;
}

.form-group input {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 14px;
}

.modal-footer {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 24px;
}
</style>

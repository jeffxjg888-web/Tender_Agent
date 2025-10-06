<template>
  <div class="bid-generation">
    <div class="card">
      <div class="card-header">
        <h3>标书生成</h3>
        <button @click="showGenerateModal = true">新建标书</button>
      </div>

      <table v-if="bidDocuments.length > 0">
        <thead>
          <tr>
            <th>标书名称</th>
            <th>类型</th>
            <th>状态</th>
            <th>进度</th>
            <th>创建时间</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in bidDocuments" :key="item.id">
            <td>{{ item.document_name }}</td>
            <td>
              <span class="badge info">{{ item.document_type }}</span>
            </td>
            <td>
              <span :class="['badge', getStatusClass(item.status)]">
                {{ getStatusText(item.status) }}
              </span>
            </td>
            <td>
              <div class="progress-bar">
                <div class="progress-bar-fill" :style="{ width: item.progress + '%' }"></div>
              </div>
              <span style="font-size: 12px; color: #666; margin-top: 4px; display: block;">
                {{ item.progress }}%
              </span>
            </td>
            <td>{{ formatDate(item.created_at) }}</td>
            <td>
              <button v-if="item.status === 'completed'" @click="viewDocument(item)" style="margin-right: 8px">
                查看
              </button>
              <button v-if="item.status === 'completed'" class="secondary" style="margin-right: 8px">
                导出
              </button>
              <button class="danger" @click="deleteDocument(item.id)">删除</button>
            </td>
          </tr>
        </tbody>
      </table>
      <div v-else class="empty-state">
        暂无标书记录
      </div>
    </div>

    <div v-if="showGenerateModal" class="modal" @click.self="closeGenerateModal">
      <div class="modal-content large">
        <div class="modal-header">
          <h3>生成标书</h3>
          <button class="close-btn" @click="closeGenerateModal">×</button>
        </div>
        <form @submit.prevent="generateBid" class="modal-body">
          <div class="form-group">
            <label>标书名称 *</label>
            <input v-model="generateForm.document_name" required />
          </div>

          <div class="form-group">
            <label>选择企业 *</label>
            <select v-model="generateForm.company_id" required @change="loadCompanyKnowledge">
              <option value="">请选择企业</option>
              <option v-for="company in companies" :key="company.id" :value="company.id">
                {{ company.company_name }}
              </option>
            </select>
          </div>

          <div class="form-group">
            <label>选择招标文件 *</label>
            <select v-model="generateForm.tender_document_id" required>
              <option value="">请选择招标文件</option>
              <option v-for="tender in tenderDocuments" :key="tender.id" :value="tender.id">
                {{ tender.document_name }}
              </option>
            </select>
          </div>

          <div class="form-group">
            <label>标书类型 *</label>
            <select v-model="generateForm.document_type" required>
              <option value="">请选择类型</option>
              <option value="商务文件">商务文件</option>
              <option value="技术文件">技术文件</option>
            </select>
          </div>

          <div class="form-group" v-if="generateForm.company_id">
            <label>选择知识库内容</label>
            <div class="checkbox-group">
              <label class="checkbox-label">
                <input type="checkbox" v-model="generateForm.use_basic_info" />
                企业基础信息
              </label>
              <label class="checkbox-label">
                <input type="checkbox" v-model="generateForm.use_qualifications" @change="toggleDetailedSelection('qualifications')" />
                资质信息
              </label>
              <label class="checkbox-label">
                <input type="checkbox" v-model="generateForm.use_financial" @change="toggleDetailedSelection('financial')" />
                财务信息
              </label>
              <label class="checkbox-label">
                <input type="checkbox" v-model="generateForm.use_performance" @change="toggleDetailedSelection('performance')" />
                业绩信息
              </label>
              <label class="checkbox-label">
                <input type="checkbox" v-model="generateForm.use_personnel" @change="toggleDetailedSelection('personnel')" />
                人员信息
              </label>
              <label class="checkbox-label">
                <input type="checkbox" v-model="generateForm.use_historical" @change="toggleDetailedSelection('historical')" />
                历史投标文件
              </label>
            </div>
          </div>

          <div class="detailed-selections" v-if="hasDetailedSelections">
            <h4>详细选择</h4>
            <DetailedSelection
              v-if="generateForm.use_personnel"
              category="personnel"
              :items="personnelList"
              v-model="generateForm.selected_personnel"
            />
            <DetailedSelection
              v-if="generateForm.use_qualifications"
              category="qualifications"
              :items="qualificationsList"
              v-model="generateForm.selected_qualifications"
            />
            <DetailedSelection
              v-if="generateForm.use_financial"
              category="financial"
              :items="financialList"
              v-model="generateForm.selected_financial"
            />
            <DetailedSelection
              v-if="generateForm.use_performance"
              category="performance"
              :items="performanceList"
              v-model="generateForm.selected_performance"
            />
            <DetailedSelection
              v-if="generateForm.use_historical"
              category="historical"
              :items="historicalList"
              v-model="generateForm.selected_historical"
            />
          </div>

          <div class="modal-footer">
            <button type="submit" :disabled="generating">
              {{ generating ? '生成中...' : '开始生成' }}
            </button>
            <button type="button" class="secondary" @click="closeGenerateModal">取消</button>
          </div>
        </form>
      </div>
    </div>

    <div v-if="showViewModal" class="modal" @click.self="showViewModal = false">
      <div class="modal-content large">
        <div class="modal-header">
          <h3>标书详情</h3>
          <button class="close-btn" @click="showViewModal = false">×</button>
        </div>
        <div class="modal-body" v-if="viewingDocument">
          <div class="view-section">
            <h4>基本信息</h4>
            <div class="info-grid">
              <div class="info-item">
                <label>标书名称</label>
                <div>{{ viewingDocument.document_name }}</div>
              </div>
              <div class="info-item">
                <label>文档类型</label>
                <div>{{ viewingDocument.document_type }}</div>
              </div>
              <div class="info-item">
                <label>状态</label>
                <div>
                  <span :class="['badge', getStatusClass(viewingDocument.status)]">
                    {{ getStatusText(viewingDocument.status) }}
                  </span>
                </div>
              </div>
              <div class="info-item">
                <label>创建时间</label>
                <div>{{ formatDate(viewingDocument.created_at) }}</div>
              </div>
            </div>
          </div>

          <div class="view-section" v-if="viewingDocument.generated_content">
            <h4>生成内容</h4>
            <div class="content-preview">
              {{ viewingDocument.generated_content }}
            </div>
          </div>

          <div class="view-section">
            <h4>使用的知识库</h4>
            <div class="knowledge-tags">
              <span v-if="viewingDocument.use_basic_info" class="tag">企业基础信息</span>
              <span v-if="viewingDocument.use_qualifications" class="tag">资质信息</span>
              <span v-if="viewingDocument.use_financial" class="tag">财务信息</span>
              <span v-if="viewingDocument.use_performance" class="tag">业绩信息</span>
              <span v-if="viewingDocument.use_personnel" class="tag">人员信息</span>
              <span v-if="viewingDocument.use_historical" class="tag">历史投标</span>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="secondary" @click="showViewModal = false">关闭</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { supabase } from '../lib/supabase'
import DetailedSelection from '../components/DetailedSelection.vue'

const bidDocuments = ref<any[]>([])
const tenderDocuments = ref<any[]>([])
const companies = ref<any[]>([])
const personnelList = ref<any[]>([])
const qualificationsList = ref<any[]>([])
const financialList = ref<any[]>([])
const performanceList = ref<any[]>([])
const historicalList = ref<any[]>([])
const showGenerateModal = ref(false)
const showViewModal = ref(false)
const viewingDocument = ref<any>(null)
const generating = ref(false)

const hasDetailedSelections = computed(() => {
  return generateForm.value.use_personnel ||
    generateForm.value.use_qualifications ||
    generateForm.value.use_financial ||
    generateForm.value.use_performance ||
    generateForm.value.use_historical
})

const generateForm = ref({
  document_name: '',
  company_id: '',
  tender_document_id: '',
  document_type: '',
  use_basic_info: false,
  use_qualifications: false,
  use_financial: false,
  use_performance: false,
  use_personnel: false,
  use_historical: false,
  selected_personnel: [] as string[],
  selected_qualifications: [] as string[],
  selected_financial: [] as string[],
  selected_performance: [] as string[],
  selected_historical: [] as string[]
})

const toggleDetailedSelection = async (category: string) => {
  if (category === 'personnel' && generateForm.value.use_personnel && personnelList.value.length === 0) {
    await loadPersonnel()
  } else if (category === 'qualifications' && generateForm.value.use_qualifications && qualificationsList.value.length === 0) {
    await loadQualifications()
  } else if (category === 'financial' && generateForm.value.use_financial && financialList.value.length === 0) {
    await loadFinancial()
  } else if (category === 'performance' && generateForm.value.use_performance && performanceList.value.length === 0) {
    await loadPerformance()
  } else if (category === 'historical' && generateForm.value.use_historical && historicalList.value.length === 0) {
    await loadHistorical()
  }
}

const loadBidDocuments = async () => {
  try {
    const { data, error } = await supabase
      .from('bid_documents')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) throw error
    bidDocuments.value = data || []
  } catch (error) {
    console.error('Error loading bid documents:', error)
  }
}

const loadTenderDocuments = async () => {
  try {
    const { data, error } = await supabase
      .from('tender_documents')
      .select('id, document_name')
      .eq('status', 'parsed')
      .order('created_at', { ascending: false })

    if (error) throw error
    tenderDocuments.value = data || []
  } catch (error) {
    console.error('Error loading tender documents:', error)
  }
}

const loadCompanies = async () => {
  try {
    const { data, error } = await supabase
      .from('companies')
      .select('*')
      .order('created_at', { ascending: false })
    if (error) throw error
    companies.value = data || []
  } catch (error) {
    console.error('Error loading companies:', error)
  }
}

const loadCompanyKnowledge = async () => {
  if (!generateForm.value.company_id) return

  // 清空之前的知识库数据
  personnelList.value = []
  qualificationsList.value = []
  financialList.value = []
  performanceList.value = []
  historicalList.value = []
}

const loadPersonnel = async () => {
  if (!generateForm.value.company_id) return
  try {
    const { data, error } = await supabase
      .from('company_personnel')
      .select('*')
      .eq('company_id', generateForm.value.company_id)
      .order('created_at', { ascending: false })
    if (error) throw error
    personnelList.value = data || []
  } catch (error) {
    console.error('Error loading personnel:', error)
  }
}

const loadQualifications = async () => {
  try {
    if (!generateForm.value.company_id) return
    const { data, error } = await supabase
      .from('company_qualifications')
      .select('*')
      .eq('company_id', generateForm.value.company_id)
      .order('created_at', { ascending: false })
    if (error) throw error
    qualificationsList.value = data || []
  } catch (error) {
    console.error('Error loading qualifications:', error)
  }
}

const loadFinancial = async () => {
  try {
    if (!generateForm.value.company_id) return
    const { data, error } = await supabase
      .from('company_financial_info')
      .select('*')
      .eq('company_id', generateForm.value.company_id)
      .order('year', { ascending: false })
    if (error) throw error
    financialList.value = data || []
  } catch (error) {
    console.error('Error loading financial info:', error)
  }
}

const loadPerformance = async () => {
  try {
    if (!generateForm.value.company_id) return
    const { data, error } = await supabase
      .from('company_performance')
      .select('*')
      .eq('company_id', generateForm.value.company_id)
      .order('contract_date', { ascending: false })
    if (error) throw error
    performanceList.value = data || []
  } catch (error) {
    console.error('Error loading performance:', error)
  }
}

const loadHistorical = async () => {
  try {
    if (!generateForm.value.company_id) return
    const { data, error } = await supabase
      .from('company_historical_bids')
      .select('*')
      .eq('company_id', generateForm.value.company_id)
      .order('created_at', { ascending: false })
    if (error) throw error
    historicalList.value = data || []
  } catch (error) {
    console.error('Error loading historical bids:', error)
  }
}

const generateBid = async () => {
  if (!generateForm.value.tender_document_id) {
    alert('请先选择招标文件')
    return
  }

  generating.value = true
  try {
    const { data: { user } } = await supabase.auth.getUser()

    const selectedKnowledge = {
      basic_info: generateForm.value.use_basic_info,
      qualifications: generateForm.value.use_qualifications,
      financial: generateForm.value.use_financial,
      performance: generateForm.value.use_performance,
      personnel: generateForm.value.use_personnel,
      historical: generateForm.value.use_historical,
      selected_personnel_ids: generateForm.value.selected_personnel,
      selected_qualifications_ids: generateForm.value.selected_qualifications,
      selected_financial_ids: generateForm.value.selected_financial,
      selected_performance_ids: generateForm.value.selected_performance,
      selected_historical_ids: generateForm.value.selected_historical
    }

    const dataToSave = {
      document_name: generateForm.value.document_name,
      tender_document_id: generateForm.value.tender_document_id,
      document_type: generateForm.value.document_type,
      status: 'generating',
      progress: 0,
      selected_knowledge: selectedKnowledge,
      created_by: user?.id
    }

    const { data: newBid, error } = await supabase
      .from('bid_documents')
      .insert(dataToSave)
      .select()
      .single()

    if (error) throw error

    alert('标书生成任务已创建')
    closeGenerateModal()
    await loadBidDocuments()

    simulateProgress(newBid.id)
  } catch (error) {
    console.error('Error generating bid:', error)
    alert('生成失败')
  } finally {
    generating.value = false
  }
}

const simulateProgress = async (bidId: string) => {
  const progressSteps = [20, 40, 60, 80, 100]

  for (const progress of progressSteps) {
    await new Promise(resolve => setTimeout(resolve, 2000))

    const status = progress === 100 ? 'completed' : 'generating'

    await supabase
      .from('bid_documents')
      .update({ progress, status })
      .eq('id', bidId)

    await loadBidDocuments()
  }
}

const viewDocument = (document: any) => {
  viewingDocument.value = document
  showViewModal.value = true
}

const deleteDocument = async (id: string) => {
  if (!confirm('确定要删除这个标书吗？')) return

  try {
    // 先删除关联的 bid_checks 记录
    const { error: checksError } = await supabase
      .from('bid_checks')
      .delete()
      .eq('bid_document_id', id)

    if (checksError) throw checksError

    // 再删除标书文档
    const { error } = await supabase
      .from('bid_documents')
      .delete()
      .eq('id', id)

    if (error) throw error

    alert('删除成功')
    await loadBidDocuments()
  } catch (error: any) {
    console.error('Error deleting document:', error)
    alert('删除失败: ' + (error.message || '未知错误'))
  }
}

const closeGenerateModal = () => {
  showGenerateModal.value = false
  generateForm.value = {
    document_name: '',
    company_id: '',
    tender_document_id: '',
    document_type: '',
    use_basic_info: false,
    use_qualifications: false,
    use_financial: false,
    use_performance: false,
    use_personnel: false,
    use_historical: false,
    selected_personnel: [],
    selected_qualifications: [],
    selected_financial: [],
    selected_performance: [],
    selected_historical: []
  }
}

const getStatusClass = (status: string) => {
  const statusMap: Record<string, string> = {
    generating: 'info',
    completed: 'success',
    error: 'danger'
  }
  return statusMap[status] || 'info'
}

const getStatusText = (status: string) => {
  const textMap: Record<string, string> = {
    generating: '生成中',
    completed: '已完成',
    error: '生成失败'
  }
  return textMap[status] || status
}

const formatDate = (date: string) => {
  if (!date) return '-'
  return new Date(date).toLocaleString('zh-CN')
}

onMounted(() => {
  loadBidDocuments()
  loadTenderDocuments()
  loadCompanies()
})
</script>

<style scoped>
.bid-generation {
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

.modal-content.large {
  max-width: 700px;
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

.checkbox-group {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
  padding: 12px;
  background: #f9f9f9;
  border-radius: 6px;
}

.checkbox-label {
  display: flex;
  align-items: center;
  font-weight: normal;
  cursor: pointer;
}

.checkbox-label input[type="checkbox"] {
  width: auto;
  margin-right: 8px;
}

.detailed-selections {
  margin-top: 24px;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
}

.detailed-selections h4 {
  margin: 0 0 16px 0;
  font-size: 16px;
  color: #333;
}

.detailed-selections > * + * {
  margin-top: 16px;
}
</style>

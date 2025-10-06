<template>
  <div class="bid-check">
    <div class="actions-row">
      <button @click="showCheckModal = true">新建检查</button>
      <button class="secondary" @click="showCustomCheckModal = true">自定义检查点</button>
    </div>

    <div class="card">
      <div class="card-header">
        <h3>标书检查记录</h3>
      </div>

      <table v-if="checkRecords.length > 0">
        <thead>
          <tr>
            <th>检查对象</th>
            <th>招标文件</th>
            <th>状态</th>
            <th>发现问题</th>
            <th>检查时间</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in checkRecords" :key="item.id">
            <td>{{ getCheckSource(item) }}</td>
            <td>{{ getTenderName(item.tender_document_id) }}</td>
            <td>
              <span :class="['badge', getStatusClass(item.check_status)]">
                {{ getStatusText(item.check_status) }}
              </span>
            </td>
            <td>
              <span :class="['badge', item.issues_found > 0 ? 'danger' : 'success']">
                {{ item.issues_found }} 个问题
              </span>
            </td>
            <td>{{ formatDate(item.created_at) }}</td>
            <td>
              <button class="secondary" @click="viewCheckResult(item)">查看结果</button>
            </td>
          </tr>
        </tbody>
      </table>
      <div v-else class="empty-state">
        暂无检查记录
      </div>
    </div>

    <div v-if="showCheckModal" class="modal" @click.self="closeCheckModal">
      <div class="modal-content">
        <div class="modal-header">
          <h3>新建标书检查</h3>
          <button class="close-btn" @click="closeCheckModal">×</button>
        </div>
        <form @submit.prevent="startCheck" class="modal-body">
          <div class="form-group">
            <label>检查来源 *</label>
            <select v-model="checkForm.source_type" required @change="onSourceTypeChange">
              <option value="">请选择</option>
              <option value="generated">已生成标书</option>
              <option value="uploaded">上传文件</option>
            </select>
          </div>

          <div class="form-group" v-if="checkForm.source_type === 'generated'">
            <label>选择标书 *</label>
            <select v-model="checkForm.bid_document_id" required>
              <option value="">请选择标书</option>
              <option v-for="bid in bidDocuments" :key="bid.id" :value="bid.id">
                {{ bid.document_name }}
              </option>
            </select>
          </div>

          <div class="form-group" v-if="checkForm.source_type === 'uploaded'">
            <label>上传文件（Word或PDF）*</label>
            <FileUpload
              accept=".doc,.docx,.pdf"
              acceptText="支持 Word、PDF 格式"
              @uploaded="(url) => checkForm.upload_file_url = url"
            />
          </div>

          <div class="form-group">
            <label>选择招标文件 *</label>
            <select v-model="checkForm.tender_document_id" required>
              <option value="">请选择招标文件</option>
              <option v-for="tender in tenderDocuments" :key="tender.id" :value="tender.id">
                {{ tender.document_name }}
              </option>
            </select>
          </div>

          <div class="modal-footer">
            <button type="submit" :disabled="checking">
              {{ checking ? '检查中...' : '开始检查' }}
            </button>
            <button type="button" class="secondary" @click="closeCheckModal">取消</button>
          </div>
        </form>
      </div>
    </div>

    <div v-if="showCustomCheckModal" class="modal" @click.self="closeCustomCheckModal">
      <div class="modal-content">
        <div class="modal-header">
          <h3>自定义检查点管理</h3>
          <button class="close-btn" @click="closeCustomCheckModal">×</button>
        </div>
        <div class="modal-body">
          <button @click="showAddCheckPoint = true" style="margin-bottom: 16px">添加检查点</button>

          <table v-if="customCheckPoints.length > 0">
            <thead>
              <tr>
                <th>检查点名称</th>
                <th>类型</th>
                <th>状态</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="point in customCheckPoints" :key="point.id">
                <td>{{ point.check_name }}</td>
                <td>{{ point.check_type }}</td>
                <td>
                  <span :class="['badge', point.is_active ? 'success' : 'warning']">
                    {{ point.is_active ? '启用' : '禁用' }}
                  </span>
                </td>
                <td>
                  <button class="secondary" @click="toggleCheckPoint(point)" style="margin-right: 8px">
                    {{ point.is_active ? '禁用' : '启用' }}
                  </button>
                  <button class="danger" @click="deleteCheckPoint(point.id)">删除</button>
                </td>
              </tr>
            </tbody>
          </table>
          <div v-else class="empty-state">
            暂无自定义检查点
          </div>
        </div>
      </div>
    </div>

    <div v-if="showAddCheckPoint" class="modal" @click.self="showAddCheckPoint = false">
      <div class="modal-content">
        <div class="modal-header">
          <h3>添加检查点</h3>
          <button class="close-btn" @click="showAddCheckPoint = false">×</button>
        </div>
        <form @submit.prevent="addCheckPoint" class="modal-body">
          <div class="form-group">
            <label>检查点名称 *</label>
            <input v-model="checkPointForm.check_name" required />
          </div>
          <div class="form-group">
            <label>检查类型 *</label>
            <select v-model="checkPointForm.check_type" required>
              <option value="">请选择</option>
              <option value="格式检查">格式检查</option>
              <option value="内容检查">内容检查</option>
              <option value="完整性检查">完整性检查</option>
            </select>
          </div>
          <div class="form-group">
            <label>检查描述</label>
            <textarea v-model="checkPointForm.check_description" rows="3"></textarea>
          </div>
          <div class="modal-footer">
            <button type="submit">保存</button>
            <button type="button" class="secondary" @click="showAddCheckPoint = false">取消</button>
          </div>
        </form>
      </div>
    </div>

    <div v-if="showResultModal" class="modal" @click.self="closeResultModal">
      <div class="modal-content large">
        <div class="modal-header">
          <h3>标书检查结果</h3>
          <button class="close-btn" @click="closeResultModal">×</button>
        </div>
        <div class="modal-body check-result-body">
          <div v-if="currentResult">
            <!-- 总体评估 -->
            <div class="result-summary">
              <div class="summary-card">
                <div class="summary-icon" :class="currentResult.issues_found === 0 ? 'success' : 'warning'">
                  {{ currentResult.issues_found === 0 ? '✓' : '!' }}
                </div>
                <div class="summary-text">
                  <div class="summary-title">
                    {{ currentResult.issues_found === 0 ? '检查通过' : '发现问题' }}
                  </div>
                  <div class="summary-desc">
                    共检查 {{ getCheckItemCount(currentResult.check_results) }} 项，
                    发现 {{ currentResult.issues_found }} 个问题
                  </div>
                </div>
              </div>
            </div>

            <!-- 检查项详情 -->
            <div class="check-items">
              <div
                v-for="(item, index) in parseCheckResults(currentResult.check_results)"
                :key="index"
                class="check-item"
                :class="item.status"
              >
                <div class="check-item-header">
                  <div class="check-item-title">
                    <span class="check-item-icon">
                      {{ item.status === 'pass' ? '✓' : '✕' }}
                    </span>
                    <span class="check-item-name">{{ item.name }}</span>
                  </div>
                  <span class="check-item-badge" :class="item.status">
                    {{ item.status === 'pass' ? '合格' : '不合格' }}
                  </span>
                </div>
                <div class="check-item-content" v-if="item.reason">
                  <div class="check-item-label">原因：</div>
                  <div class="check-item-text">{{ item.reason }}</div>
                </div>
                <div class="check-item-content" v-if="item.requirement">
                  <div class="check-item-label">要求：</div>
                  <div class="check-item-text">{{ item.requirement }}</div>
                </div>
                <div class="check-item-content" v-if="item.suggestion">
                  <div class="check-item-label">建议：</div>
                  <div class="check-item-text">{{ item.suggestion }}</div>
                </div>
              </div>
            </div>

            <!-- 废标项单独展示 -->
            <div class="critical-issues" v-if="getCriticalIssues(currentResult.check_results).length > 0">
              <h4 class="critical-title">⚠️ 废标项</h4>
              <div
                v-for="(issue, index) in getCriticalIssues(currentResult.check_results)"
                :key="index"
                class="critical-item"
              >
                <div class="critical-item-header">{{ issue.name }}</div>
                <div class="critical-item-content">{{ issue.reason }}</div>
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button class="secondary" @click="closeResultModal">关闭</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '../lib/supabase'
import FileUpload from '../components/FileUpload.vue'

const checkRecords = ref<any[]>([])
const bidDocuments = ref<any[]>([])
const tenderDocuments = ref<any[]>([])
const customCheckPoints = ref<any[]>([])
const showCheckModal = ref(false)
const showCustomCheckModal = ref(false)
const showAddCheckPoint = ref(false)
const showResultModal = ref(false)
const currentResult = ref<any>(null)
const checking = ref(false)

const checkForm = ref({
  source_type: '',
  bid_document_id: '',
  upload_file_url: '',
  tender_document_id: ''
})

const checkPointForm = ref({
  check_name: '',
  check_type: '',
  check_description: ''
})

const loadCheckRecords = async () => {
  try {
    const { data, error } = await supabase
      .from('bid_checks')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) throw error
    checkRecords.value = data || []
  } catch (error) {
    console.error('Error loading check records:', error)
  }
}

const loadBidDocuments = async () => {
  try {
    const { data, error } = await supabase
      .from('bid_documents')
      .select('id, document_name')
      .eq('status', 'completed')
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

const loadCustomCheckPoints = async () => {
  try {
    const { data, error } = await supabase
      .from('custom_check_points')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) throw error
    customCheckPoints.value = data || []
  } catch (error) {
    console.error('Error loading custom check points:', error)
  }
}

const onSourceTypeChange = () => {
  checkForm.value.bid_document_id = ''
  checkForm.value.upload_file_url = ''
}

const startCheck = async () => {
  checking.value = true
  try {
    const { data: { user } } = await supabase.auth.getUser()

    const dataToSave = {
      bid_document_id: checkForm.value.bid_document_id || null,
      upload_file_url: checkForm.value.upload_file_url || null,
      tender_document_id: checkForm.value.tender_document_id,
      check_status: 'checking',
      issues_found: 0,
      created_by: user?.id
    }

    const { data: newCheck, error } = await supabase
      .from('bid_checks')
      .insert(dataToSave)
      .select()
      .single()

    if (error) throw error

    alert('检查任务已创建')
    closeCheckModal()
    await loadCheckRecords()

    simulateCheck(newCheck.id)
  } catch (error) {
    console.error('Error starting check:', error)
    alert('检查失败')
  } finally {
    checking.value = false
  }
}

const simulateCheck = async (checkId: string) => {
  await new Promise(resolve => setTimeout(resolve, 3000))

  const mockResults = {
    check_status: 'completed',
    issues_found: Math.floor(Math.random() * 5),
    check_results: {
      format_check: { passed: true, issues: [] },
      content_check: { passed: false, issues: ['缺少关键章节', '格式不符合要求'] },
      completeness_check: { passed: true, issues: [] }
    }
  }

  await supabase
    .from('bid_checks')
    .update(mockResults)
    .eq('id', checkId)

  await loadCheckRecords()
}

const addCheckPoint = async () => {
  try {
    const { data: { user } } = await supabase.auth.getUser()

    const dataToSave = {
      ...checkPointForm.value,
      created_by: user?.id
    }

    const { error } = await supabase
      .from('custom_check_points')
      .insert(dataToSave)

    if (error) throw error

    alert('添加成功')
    showAddCheckPoint.value = false
    checkPointForm.value = {
      check_name: '',
      check_type: '',
      check_description: ''
    }
    await loadCustomCheckPoints()
  } catch (error) {
    console.error('Error adding check point:', error)
    alert('添加失败')
  }
}

const toggleCheckPoint = async (point: any) => {
  try {
    const { error } = await supabase
      .from('custom_check_points')
      .update({ is_active: !point.is_active })
      .eq('id', point.id)

    if (error) throw error

    await loadCustomCheckPoints()
  } catch (error) {
    console.error('Error toggling check point:', error)
    alert('操作失败')
  }
}

const deleteCheckPoint = async (id: string) => {
  if (!confirm('确定要删除这个检查点吗？')) return

  try {
    const { error } = await supabase
      .from('custom_check_points')
      .delete()
      .eq('id', id)

    if (error) throw error

    alert('删除成功')
    await loadCustomCheckPoints()
  } catch (error) {
    console.error('Error deleting check point:', error)
    alert('删除失败')
  }
}

const viewCheckResult = (item: any) => {
  currentResult.value = item
  showResultModal.value = true
}

const closeCheckModal = () => {
  showCheckModal.value = false
  checkForm.value = {
    source_type: '',
    bid_document_id: '',
    upload_file_url: '',
    tender_document_id: ''
  }
}

const closeCustomCheckModal = () => {
  showCustomCheckModal.value = false
}

const closeResultModal = () => {
  showResultModal.value = false
  currentResult.value = null
}

const getCheckSource = (item: any) => {
  if (item.bid_document_id) {
    const bid = bidDocuments.value.find(b => b.id === item.bid_document_id)
    return bid ? bid.document_name : '已生成标书'
  }
  return '上传文件'
}

const getTenderName = (tenderId: string) => {
  const tender = tenderDocuments.value.find(t => t.id === tenderId)
  return tender ? tender.document_name : '-'
}

const getStatusClass = (status: string) => {
  const statusMap: Record<string, string> = {
    checking: 'info',
    completed: 'success',
    error: 'danger'
  }
  return statusMap[status] || 'info'
}

const getStatusText = (status: string) => {
  const textMap: Record<string, string> = {
    checking: '检查中',
    completed: '已完成',
    error: '检查失败'
  }
  return textMap[status] || status
}

const formatDate = (date: string) => {
  if (!date) return '-'
  return new Date(date).toLocaleString('zh-CN')
}

const parseCheckResults = (results: any) => {
  if (!results) return []

  // 如果是字符串，尝试解析为JSON
  let parsed = results
  if (typeof results === 'string') {
    try {
      parsed = JSON.parse(results)
    } catch (e) {
      return []
    }
  }

  // 如果是数组，直接返回
  if (Array.isArray(parsed)) {
    return parsed
  }

  // 如果是对象，转换为数组
  if (typeof parsed === 'object') {
    return Object.entries(parsed).map(([key, value]: [string, any]) => ({
      name: value.name || key,
      status: value.status || value.result || 'fail',
      reason: value.reason || value.message || '',
      requirement: value.requirement || '',
      suggestion: value.suggestion || '',
      isCritical: value.isCritical || value.is_critical || false
    }))
  }

  return []
}

const getCriticalIssues = (results: any) => {
  const items = parseCheckResults(results)
  return items.filter(item => item.isCritical && item.status !== 'pass')
}

const getCheckItemCount = (results: any) => {
  const items = parseCheckResults(results)
  return items.length
}

onMounted(() => {
  loadCheckRecords()
  loadBidDocuments()
  loadTenderDocuments()
  loadCustomCheckPoints()
})
</script>

<style scoped>
.bid-check {
  max-width: 1400px;
}

.actions-row {
  display: flex;
  gap: 12px;
  margin-bottom: 20px;
}

.card-header {
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
  max-width: 900px;
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

.check-result-body {
  max-height: 70vh;
  overflow-y: auto;
}

.result-summary {
  margin-bottom: 24px;
}

.summary-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 20px;
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
  border-radius: 12px;
  border-left: 4px solid #4caf50;
}

.summary-card.warning {
  border-left-color: #ff9800;
}

.summary-icon {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 32px;
  font-weight: bold;
  flex-shrink: 0;
}

.summary-icon.success {
  background: #4caf50;
  color: white;
}

.summary-icon.warning {
  background: #ff9800;
  color: white;
}

.summary-text {
  flex: 1;
}

.summary-title {
  font-size: 20px;
  font-weight: 600;
  color: #333;
  margin-bottom: 4px;
}

.summary-desc {
  font-size: 14px;
  color: #666;
}

.check-items {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.check-item {
  background: white;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  padding: 16px;
  transition: all 0.2s;
}

.check-item.pass {
  border-color: #4caf50;
  background: #f1f8f4;
}

.check-item.fail {
  border-color: #f44336;
  background: #fef5f5;
}

.check-item-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.check-item-title {
  display: flex;
  align-items: center;
  gap: 10px;
}

.check-item-icon {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  font-weight: bold;
  flex-shrink: 0;
}

.check-item.pass .check-item-icon {
  background: #4caf50;
  color: white;
}

.check-item.fail .check-item-icon {
  background: #f44336;
  color: white;
}

.check-item-name {
  font-size: 15px;
  font-weight: 600;
  color: #333;
}

.check-item-badge {
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
}

.check-item-badge.pass {
  background: #4caf50;
  color: white;
}

.check-item-badge.fail {
  background: #f44336;
  color: white;
}

.check-item-content {
  display: flex;
  gap: 8px;
  margin-top: 8px;
  font-size: 14px;
  line-height: 1.6;
}

.check-item-label {
  font-weight: 600;
  color: #666;
  flex-shrink: 0;
}

.check-item-text {
  flex: 1;
  color: #333;
}

.critical-issues {
  margin-top: 24px;
  padding: 20px;
  background: #fff3e0;
  border: 2px solid #ff9800;
  border-radius: 8px;
}

.critical-title {
  margin: 0 0 16px 0;
  font-size: 18px;
  font-weight: 600;
  color: #e65100;
}

.critical-item {
  background: white;
  padding: 12px;
  border-radius: 6px;
  margin-bottom: 8px;
  border-left: 4px solid #ff9800;
}

.critical-item:last-child {
  margin-bottom: 0;
}

.critical-item-header {
  font-size: 15px;
  font-weight: 600;
  color: #333;
  margin-bottom: 6px;
}

.critical-item-content {
  font-size: 14px;
  color: #666;
  line-height: 1.5;
}
</style>

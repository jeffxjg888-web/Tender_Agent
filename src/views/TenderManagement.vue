<template>
  <div class="tender-management">
    <div class="card">
      <div class="card-header">
        <h3>招标文件管理</h3>
        <button @click="showUploadModal = true">上传招标文件</button>
      </div>

      <table v-if="tenderDocuments.length > 0">
        <thead>
          <tr>
            <th>文件名称</th>
            <th>状态</th>
            <th>上传时间</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in tenderDocuments" :key="item.id">
            <td>{{ item.document_name }}</td>
            <td>
              <span :class="['badge', getStatusClass(item.status)]">
                {{ getStatusText(item.status) }}
              </span>
            </td>
            <td>{{ formatDate(item.created_at) }}</td>
            <td>
              <button class="secondary" @click="viewDocument(item)" style="margin-right: 8px">
                查看解析
              </button>
              <button v-if="item.status === 'uploaded'" @click="parseDocument(item)" style="margin-right: 8px">
                开始解析
              </button>
              <button class="danger" @click="deleteDocument(item.id)">删除</button>
            </td>
          </tr>
        </tbody>
      </table>
      <div v-else class="empty-state">
        暂无招标文件
      </div>
    </div>

    <div v-if="showUploadModal" class="modal" @click.self="closeUploadModal">
      <div class="modal-content">
        <div class="modal-header">
          <h3>上传招标文件</h3>
          <button class="close-btn" @click="closeUploadModal">×</button>
        </div>
        <form @submit.prevent="uploadDocument" class="modal-body">
          <div class="form-group">
            <label>上传招标文件</label>
            <FileUpload
              accept=".pdf,.doc,.docx"
              acceptText="支持 PDF、DOC、DOCX 格式"
              @uploaded="handleFileUploaded"
            />
          </div>

          <div class="form-group">
            <label>文件名称 *</label>
            <input v-model="uploadForm.document_name" required />
          </div>

          <div class="modal-footer">
            <button type="submit" :disabled="uploading || !uploadForm.document_url">上传</button>
            <button type="button" class="secondary" @click="closeUploadModal">取消</button>
          </div>
        </form>
      </div>
    </div>

    <div v-if="showDetailModal" class="modal" @click.self="closeDetailModal">
      <div class="modal-content extra-large">
        <div class="modal-header">
          <h3>招标文件解析结果</h3>
          <button class="close-btn" @click="closeDetailModal">×</button>
        </div>
        <div class="modal-body parse-result-body">
          <div v-if="currentDocument">
            <!-- 基础信息 -->
            <div class="parse-section">
              <h4 class="parse-section-title">📋 基础信息</h4>
              <div class="parse-content">
                <div v-for="(value, key) in parseSectionData(currentDocument.parsed_basic_info)" :key="String(key)" class="parse-item">
                  <span class="parse-label">{{ formatLabel(String(key)) }}:</span>
                  <span class="parse-value">{{ value }}</span>
                </div>
              </div>
            </div>

            <!-- 资格要求 -->
            <div class="parse-section">
              <h4 class="parse-section-title">✓ 资格要求</h4>
              <div class="parse-content">
                <div v-for="(item, index) in parseListData(currentDocument.parsed_requirements)" :key="index" class="parse-list-item">
                  <span class="parse-bullet">{{ index + 1 }}.</span>
                  <span class="parse-text">{{ item }}</span>
                </div>
              </div>
            </div>

            <!-- 评审要求 -->
            <div class="parse-section">
              <h4 class="parse-section-title">📊 评审要求</h4>
              <div class="parse-content">
                <div v-for="(item, index) in parseListData(currentDocument.parsed_evaluation)" :key="index" class="parse-list-item">
                  <span class="parse-bullet">{{ index + 1 }}.</span>
                  <span class="parse-text">{{ item }}</span>
                </div>
              </div>
            </div>

            <!-- 招标文件要求 -->
            <div class="parse-section" v-if="currentDocument.parsed_document_requirements">
              <h4 class="parse-section-title">📄 招标文件要求</h4>
              <div class="parse-content">
                <div v-for="(item, index) in parseListData(currentDocument.parsed_document_requirements)" :key="index" class="parse-list-item">
                  <span class="parse-bullet">{{ index + 1 }}.</span>
                  <span class="parse-text">{{ item }}</span>
                </div>
              </div>
            </div>

            <!-- 风险项/废标项 -->
            <div class="parse-section risk-section">
              <h4 class="parse-section-title">⚠️ 风险项/废标项</h4>
              <div class="parse-content">
                <div v-for="(item, index) in parseListData(currentDocument.parsed_risks)" :key="index" class="risk-item">
                  <span class="risk-icon">⚠</span>
                  <span class="risk-text">{{ item }}</span>
                </div>
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button class="secondary" @click="closeDetailModal">关闭</button>
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

const tenderDocuments = ref<any[]>([])
const showUploadModal = ref(false)
const showDetailModal = ref(false)
const currentDocument = ref<any>(null)
const uploading = ref(false)

const uploadForm = ref({
  document_name: '',
  document_url: ''
})

const handleFileUploaded = (url: string, file: File) => {
  uploadForm.value.document_url = url
  if (!uploadForm.value.document_name) {
    uploadForm.value.document_name = file.name.replace(/\.[^/.]+$/, '')
  }
}

const loadDocuments = async () => {
  try {
    const { data, error } = await supabase
      .from('tender_documents')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) throw error
    tenderDocuments.value = data || []
  } catch (error) {
    console.error('Error loading tender documents:', error)
  }
}

const uploadDocument = async () => {
  uploading.value = true
  try {
    const { data: { user }, error: userError } = await supabase.auth.getUser()

    if (userError) {
      throw new Error('获取用户信息失败: ' + userError.message)
    }

    if (!user?.id) {
      throw new Error('未找到用户信息，请重新登录')
    }

    console.log('Current user ID:', user.id)

    const dataToSave = {
      document_name: uploadForm.value.document_name,
      document_url: uploadForm.value.document_url,
      status: 'uploaded',
      uploaded_by: user.id
    }

    console.log('Uploading document:', dataToSave)

    const { data, error } = await supabase
      .from('tender_documents')
      .insert(dataToSave)
      .select()

    if (error) {
      console.error('Insert error:', error)
      throw new Error(error.message || '保存失败')
    }

    console.log('Upload successful:', data)
    alert('上传成功')
    closeUploadModal()
    await loadDocuments()
  } catch (error: any) {
    console.error('Error uploading document:', error)
    alert('上传失败: ' + (error.message || '未知错误'))
  } finally {
    uploading.value = false
  }
}

const parseDocument = async (item: any) => {
  try {
    alert('开始解析招标文件...')

    await new Promise(resolve => setTimeout(resolve, 2000))

    const mockParsedData = {
      parsed_basic_info: {
        project_name: '智慧城市综合管理平台建设项目',
        budget: '500万元',
        deadline: '2024-12-31',
        project_location: '某市政府大楼',
        contact_person: '李经理',
        contact_phone: '138-xxxx-xxxx'
      },
      parsed_requirements: {
        qualifications: [
          '具有软件开发相关资质',
          '注册资金不低于500万元',
          '近三年内具有类似项目经验'
        ],
        experience: '3年以上智慧城市相关项目经验',
        technical_requirements: [
          '支持高并发访问',
          '提供7x24小时运维服务',
          '数据安全符合国家标准'
        ]
      },
      parsed_evaluation: {
        criteria: [
          '技术方案：40分',
          '商务报价：30分',
          '资质业绩：20分',
          '售后服务：10分'
        ],
        total_score: 100
      },
      parsed_risks: {
        disqualifications: [
          '未按时提交投标文件',
          '资质证书过期或不符合要求',
          '报价超出预算范围',
          '未提供投标保证金'
        ],
        warnings: [
          '所有文件需加盖公章',
          '技术方案需详细说明实施方案',
          '业绩证明需提供合同复印件',
          '报价清单需详细列明各项费用'
        ]
      },
      status: 'parsed'
    }

    const { error } = await supabase
      .from('tender_documents')
      .update(mockParsedData)
      .eq('id', item.id)

    if (error) throw error

    alert('招标文件解析完成！已提取关键信息。')
    await loadDocuments()
  } catch (error) {
    console.error('Error parsing document:', error)
    alert('解析失败')
  }
}

const viewDocument = (item: any) => {
  currentDocument.value = item
  showDetailModal.value = true
}

const deleteDocument = async (id: string) => {
  if (!confirm('确定要删除这个招标文件吗？')) return

  try {
    const { error } = await supabase
      .from('tender_documents')
      .delete()
      .eq('id', id)

    if (error) throw error

    alert('删除成功')
    await loadDocuments()
  } catch (error) {
    console.error('Error deleting document:', error)
    alert('删除失败')
  }
}

const closeUploadModal = () => {
  showUploadModal.value = false
  uploadForm.value = {
    document_name: '',
    document_url: ''
  }
}

const closeDetailModal = () => {
  showDetailModal.value = false
  currentDocument.value = null
}

const getStatusClass = (status: string) => {
  const statusMap: Record<string, string> = {
    uploaded: 'warning',
    parsing: 'info',
    parsed: 'success',
    error: 'danger'
  }
  return statusMap[status] || 'info'
}

const getStatusText = (status: string) => {
  const textMap: Record<string, string> = {
    uploaded: '已上传',
    parsing: '解析中',
    parsed: '已解析',
    error: '解析失败'
  }
  return textMap[status] || status
}

const formatDate = (date: string) => {
  if (!date) return '-'
  return new Date(date).toLocaleString('zh-CN')
}

const parseSectionData = (data: any) => {
  if (!data) return {}

  // 如果是字符串，尝试解析为JSON
  if (typeof data === 'string') {
    try {
      return JSON.parse(data)
    } catch (e) {
      return { content: data }
    }
  }

  return data
}

const parseListData = (data: any) => {
  if (!data) return []

  // 如果是字符串，尝试解析为JSON
  let parsed = data
  if (typeof data === 'string') {
    try {
      parsed = JSON.parse(data)
    } catch (e) {
      // 如果不是JSON，尝试按行分割
      return data.split('\n').filter((line: string) => line.trim())
    }
  }

  // 如果是数组，直接返回
  if (Array.isArray(parsed)) {
    return parsed
  }

  // 如果是对象，转换为数组
  if (typeof parsed === 'object') {
    return Object.values(parsed).filter(v => v)
  }

  return []
}

const formatLabel = (key: string) => {
  const labelMap: Record<string, string> = {
    project_name: '项目名称',
    bidding_unit: '招标单位',
    contact: '联系人',
    phone: '联系电话',
    budget: '预算金额',
    deadline: '投标截止时间',
    location: '项目地点',
    duration: '项目周期'
  }

  return labelMap[key] || key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
}

onMounted(() => {
  loadDocuments()
})
</script>

<style scoped>
.tender-management {
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

.modal-content.extra-large {
  max-width: 900px;
}

.parse-result-body {
  max-height: 70vh;
  overflow-y: auto;
}

.parse-section {
  margin-bottom: 32px;
  padding: 20px;
  background: white;
  border-radius: 8px;
  border: 1px solid #e0e0e0;
}

.parse-section:last-of-type {
  margin-bottom: 0;
}

.parse-section-title {
  margin: 0 0 16px 0;
  font-size: 18px;
  font-weight: 600;
  color: #333;
  padding-bottom: 12px;
  border-bottom: 2px solid #2196f3;
}

.parse-content {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.parse-item {
  display: flex;
  gap: 12px;
  padding: 12px;
  background: #f8f9fa;
  border-radius: 6px;
}

.parse-label {
  font-weight: 600;
  color: #666;
  min-width: 120px;
  flex-shrink: 0;
}

.parse-value {
  flex: 1;
  color: #333;
  line-height: 1.6;
}

.parse-list-item {
  display: flex;
  gap: 12px;
  padding: 12px;
  background: #f8f9fa;
  border-radius: 6px;
  align-items: flex-start;
}

.parse-bullet {
  font-weight: 600;
  color: #2196f3;
  flex-shrink: 0;
  min-width: 24px;
}

.parse-text {
  flex: 1;
  color: #333;
  line-height: 1.6;
}

.risk-section {
  background: #fff8e1;
  border-color: #ff9800;
}

.risk-section .parse-section-title {
  border-bottom-color: #ff9800;
  color: #e65100;
}

.risk-item {
  display: flex;
  gap: 12px;
  padding: 12px;
  background: white;
  border-radius: 6px;
  border-left: 4px solid #ff9800;
  align-items: flex-start;
}

.risk-icon {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: #ff9800;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  flex-shrink: 0;
}

.risk-text {
  flex: 1;
  color: #333;
  line-height: 1.6;
  font-weight: 500;
}
</style>

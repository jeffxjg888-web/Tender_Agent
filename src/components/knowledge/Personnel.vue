<template>
  <div class="personnel">
    <div class="card">
      <div class="card-header">
        <h3>人员信息</h3>
        <button @click="showAddModal = true">添加人员</button>
      </div>

      <table v-if="personnelData.length > 0">
        <thead>
          <tr>
            <th>姓名</th>
            <th>身份证号</th>
            <th>联系电话</th>
            <th>身份证状态</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in personnelData" :key="item.id">
            <td>{{ item.name }}</td>
            <td>{{ item.id_card || '-' }}</td>
            <td>{{ item.phone || '-' }}</td>
            <td>
              <span :class="['badge', item.is_id_expired ? 'danger' : 'success']">
                {{ item.is_id_expired ? '已过期' : '有效' }}
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
        暂无人员信息
      </div>
    </div>

    <div v-if="showAddModal" class="modal" @click.self="closeModal">
      <div class="modal-content">
        <div class="modal-header">
          <h3>{{ editingItem ? '查看人员' : '添加人员' }}</h3>
          <button class="close-btn" @click="closeModal">×</button>
        </div>
        <form @submit.prevent="saveItem" class="modal-body">
          <div class="form-group">
            <label>姓名 *</label>
            <input v-model="form.name" required :disabled="!!editingItem" />
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>身份证号</label>
              <input v-model="form.id_card" :disabled="!!editingItem" />
            </div>
            <div class="form-group">
              <label>身份证有效期</label>
              <input type="date" v-model="form.id_card_expiry" :disabled="!!editingItem" />
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>联系电话</label>
              <input v-model="form.phone" :disabled="!!editingItem" />
            </div>
            <div class="form-group">
              <label>地址</label>
              <input v-model="form.address" :disabled="!!editingItem" />
            </div>
          </div>
          <div class="form-group">
            <label>工作经历</label>
            <textarea v-model="form.work_experience" rows="4" :disabled="!!editingItem"></textarea>
          </div>

          <div class="upload-section" v-if="!editingItem">
            <h4>文件上传</h4>
            <div class="form-group">
              <label>简历（Word或PDF）</label>
              <FileUpload
                accept=".doc,.docx,.pdf"
                acceptText="支持 Word、PDF 格式"
                @uploaded="(url) => form.resume_url = url"
              />
            </div>
            <div class="form-group">
              <label>身份证正反面（图片或PDF）</label>
              <FileUpload
                accept=".pdf,.jpg,.jpeg,.png"
                acceptText="支持 PDF、JPG、PNG 格式"
                @uploaded="(url) => form.id_card_url = url"
              />
            </div>
            <div class="form-group">
              <label>毕业证书（图片或PDF）</label>
              <FileUpload
                accept=".pdf,.jpg,.jpeg,.png"
                acceptText="支持 PDF、JPG、PNG 格式"
                @uploaded="(url) => form.diploma_url = url"
              />
            </div>
            <div class="form-group">
              <label>资质证书（图片或PDF）</label>
              <FileUpload
                accept=".pdf,.jpg,.jpeg,.png"
                acceptText="支持 PDF、JPG、PNG 格式"
                @uploaded="(url) => form.qualification_certificate_url = url"
              />
            </div>
            <div class="form-group">
              <label>社保（图片或PDF）</label>
              <FileUpload
                accept=".pdf,.jpg,.jpeg,.png"
                acceptText="支持 PDF、JPG、PNG 格式"
                @uploaded="(url) => form.social_security_url = url"
              />
            </div>
          </div>

          <div class="file-list" v-if="editingItem">
            <h4>已上传文件</h4>
            <div v-if="form.resume_url" class="file-item">简历</div>
            <div v-if="form.id_card_url" class="file-item">身份证</div>
            <div v-if="form.diploma_url" class="file-item">毕业证书</div>
            <div v-if="form.qualification_certificate_url" class="file-item">资质证书</div>
            <div v-if="form.social_security_url" class="file-item">社保</div>
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

const personnelData = ref<any[]>([])
const showAddModal = ref(false)
const editingItem = ref<any>(null)
const loading = ref(false)

const form = ref({
  name: '',
  id_card: '',
  id_card_expiry: '',
  phone: '',
  address: '',
  work_experience: '',
  resume_url: '',
  id_card_url: '',
  diploma_url: '',
  qualification_certificate_url: '',
  social_security_url: ''
})

const loadPersonnelData = async () => {
  try {
    const { data, error } = await supabase
      .from('company_personnel')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) {
      console.error('Database error:', error)
      throw new Error(error.message || '操作失败')
    }
    personnelData.value = data || []
  } catch (error) {
    console.error('Error loading personnel data:', error)
  }
}

const saveItem = async () => {
  loading.value = true
  try {
    const { data: { user } } = await supabase.auth.getUser()

    // 清理空字符串，将它们转换为 null
    const dataToSave = {
      ...form.value,
      id_card_expiry: form.value.id_card_expiry || null,
      created_by: user?.id,
      updated_at: new Date().toISOString()
    }

    const { error } = await supabase
      .from('company_personnel')
      .insert(dataToSave)

    if (error) {
      console.error('Database error:', error)
      throw new Error(error.message || '操作失败')
    }

    toast.success('信息已保存', '保存成功')
    closeModal()
    await loadPersonnelData()
  } catch (error: any) {
    console.error('Error saving personnel data:', error)
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
  if (!confirm('确定要删除这条人员信息吗？')) return

  try {
    const { error } = await supabase
      .from('company_personnel')
      .delete()
      .eq('id', id)

    if (error) {
      console.error('Database error:', error)
      throw new Error(error.message || '操作失败')
    }

    toast.success('信息已删除', '删除成功')
    await loadPersonnelData()
  } catch (error) {
    console.error('Error deleting personnel data:', error)
    toast.error('未知错误', '删除失败')
  }
}

const closeModal = () => {
  showAddModal.value = false
  editingItem.value = null
  form.value = {
    name: '',
    id_card: '',
    id_card_expiry: '',
    phone: '',
    address: '',
    work_experience: '',
    resume_url: '',
    id_card_url: '',
    diploma_url: '',
    qualification_certificate_url: '',
    social_security_url: ''
  }
}

onMounted(() => {
  loadPersonnelData()
})
</script>

<style scoped>
.personnel {
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

.upload-section h4 {
  margin: 0 0 16px 0;
  font-size: 15px;
  color: #555;
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

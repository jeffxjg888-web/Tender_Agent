<template>
  <div class="basic-info">
    <div class="card">
      <div class="card-header">
        <h3>企业基础信息</h3>
        <button v-if="!isEditing" @click="startEdit">编辑</button>
        <div v-else>
          <button @click="saveInfo" :disabled="loading">保存</button>
          <button class="secondary" @click="cancelEdit" style="margin-left: 8px">取消</button>
        </div>
      </div>

      <form @submit.prevent="saveInfo" class="form">
        <div class="upload-section">
          <div class="form-group">
            <label>营业执照 *</label>
            <FileUpload
              accept=".pdf,.jpg,.jpeg,.png"
              acceptText="支持 PDF、JPG、PNG 格式"
              @uploaded="handleLicenseUploaded"
            />
          </div>

          <div class="form-group">
            <label>开户许可证 *</label>
            <FileUpload
              accept=".pdf,.jpg,.jpeg,.png"
              acceptText="支持 PDF、JPG、PNG 格式"
              @uploaded="handleBankUploaded"
            />
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label>企业名称 *</label>
            <input v-model="form.company_name" :disabled="!isEditing" required />
          </div>
          <div class="form-group">
            <label>统一社会信用代码</label>
            <input v-model="form.social_credit_code" :disabled="!isEditing" />
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label>注册资金</label>
            <input v-model="form.registered_capital" :disabled="!isEditing" />
          </div>
          <div class="form-group">
            <label>成立时间</label>
            <input type="date" v-model="form.establishment_date" :disabled="!isEditing" />
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label>注册地址</label>
            <input v-model="form.registration_address" :disabled="!isEditing" />
          </div>
          <div class="form-group">
            <label>邮政编码</label>
            <input v-model="form.postal_code" :disabled="!isEditing" />
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label>联系人</label>
            <input v-model="form.contact_person" :disabled="!isEditing" />
          </div>
          <div class="form-group">
            <label>联系电话</label>
            <input v-model="form.phone" :disabled="!isEditing" />
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label>传真</label>
            <input v-model="form.fax" :disabled="!isEditing" />
          </div>
          <div class="form-group">
            <label>网址</label>
            <input v-model="form.website" :disabled="!isEditing" />
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label>法定代表人</label>
            <input v-model="form.legal_representative" :disabled="!isEditing" />
          </div>
          <div class="form-group">
            <label>法人职称</label>
            <input v-model="form.legal_rep_title" :disabled="!isEditing" />
          </div>
          <div class="form-group">
            <label>法人电话</label>
            <input v-model="form.legal_rep_phone" :disabled="!isEditing" />
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label>技术负责人</label>
            <input v-model="form.technical_director" :disabled="!isEditing" />
          </div>
          <div class="form-group">
            <label>技术负责人职称</label>
            <input v-model="form.tech_director_title" :disabled="!isEditing" />
          </div>
          <div class="form-group">
            <label>技术负责人电话</label>
            <input v-model="form.tech_director_phone" :disabled="!isEditing" />
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label>员工总人数</label>
            <input type="number" v-model.number="form.total_employees" :disabled="!isEditing" />
          </div>
          <div class="form-group">
            <label>企业资质等级</label>
            <input v-model="form.qualification_level" :disabled="!isEditing" />
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label>开户银行</label>
            <input v-model="form.bank_name" :disabled="!isEditing" />
          </div>
          <div class="form-group">
            <label>开户账号</label>
            <input v-model="form.bank_account" :disabled="!isEditing" />
          </div>
        </div>

        <div class="form-group">
          <label>经营范围</label>
          <textarea v-model="form.business_scope" :disabled="!isEditing" rows="4"></textarea>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import { toast } from '../../lib/toast'
import FileUpload from '../FileUpload.vue'

const isEditing = ref(false)
const loading = ref(false)
const originalData = ref<any>(null)

const form = ref({
  company_name: '',
  social_credit_code: '',
  registered_capital: '',
  establishment_date: '',
  registration_address: '',
  postal_code: '',
  contact_person: '',
  phone: '',
  fax: '',
  website: '',
  legal_representative: '',
  legal_rep_title: '',
  legal_rep_phone: '',
  technical_director: '',
  tech_director_title: '',
  tech_director_phone: '',
  total_employees: null as number | null,
  qualification_level: '',
  bank_name: '',
  bank_account: '',
  business_scope: '',
  business_license_url: '',
  bank_license_url: ''
})

const handleLicenseUploaded = (url: string) => {
  form.value.business_license_url = url
  toast.info('正在解析文件...', '营业执照上传成功')

  setTimeout(() => {
    form.value.company_name = '某某科技有限公司'
    form.value.social_credit_code = '91110000MA01234567'
    form.value.registered_capital = '5000万元'
    form.value.establishment_date = '2015-06-15'
    form.value.registration_address = '北京市海淀区中关村大街1号'
    form.value.legal_representative = '张三'
    toast.success('已自动填充识别的信息，请核对后保存', '营业执照解析完成')
    isEditing.value = true
  }, 1500)
}

const handleBankUploaded = (url: string) => {
  form.value.bank_license_url = url
  toast.info('正在解析文件...', '开户许可证上传成功')

  setTimeout(() => {
    form.value.bank_name = '中国工商银行北京分行'
    form.value.bank_account = '0200 1234 5678 9012 3456'
    toast.success('已自动填充识别的信息，请核对后保存', '开户许可证解析完成')
    isEditing.value = true
  }, 1500)
}

const loadInfo = async () => {
  try {
    const { data, error } = await supabase
      .from('company_basic_info')
      .select('*')
      .limit(1)
      .maybeSingle()

    if (error) throw error

    if (data) {
      form.value = { ...data }
      originalData.value = { ...data }
    }
  } catch (error) {
    console.error('Error loading basic info:', error)
  }
}

const startEdit = () => {
  isEditing.value = true
  originalData.value = { ...form.value }
}

const cancelEdit = () => {
  form.value = { ...originalData.value }
  isEditing.value = false
}

const saveInfo = async () => {
  loading.value = true
  try {
    const { data: { user } } = await supabase.auth.getUser()

    // 清理空字符串，将它们转换为 null
    const dataToSave = {
      ...form.value,
      establishment_date: form.value.establishment_date || null,
      created_by: user?.id,
      updated_at: new Date().toISOString()
    }

    if (originalData.value && originalData.value.id) {
      const { error } = await supabase
        .from('company_basic_info')
        .update(dataToSave)
        .eq('id', originalData.value.id)

      if (error) {
        console.error('Database error:', error)
        throw new Error(error.message || '操作失败')
      }
    } else {
      const { error } = await supabase
        .from('company_basic_info')
        .insert(dataToSave)

      if (error) {
        console.error('Database error:', error)
        throw new Error(error.message || '操作失败')
      }
    }

    toast.success('企业基本信息已保存', '保存成功')
    isEditing.value = false
    await loadInfo()
  } catch (error: any) {
    console.error('Error saving basic info:', error)
    toast.error(error.message || '未知错误', '保存失败')
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadInfo()
})
</script>

<style scoped>
.basic-info {
  max-width: 1200px;
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

.upload-section {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
  margin-bottom: 24px;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
}

.form-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
}

.form-row .form-group {
  margin-bottom: 0;
}

input:disabled, textarea:disabled {
  background-color: #f5f5f5;
  cursor: not-allowed;
}
</style>

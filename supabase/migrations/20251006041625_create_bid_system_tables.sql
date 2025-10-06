/*
  # 标书智能体系统数据库架构

  ## 概述
  创建标书智能体系统所需的所有数据库表，支持企业知识库管理、招标文件管理、
  标书生成和检查等核心功能。

  ## 新建表

  ### 1. 用户管理
  - `users` - 系统用户表
    - id (uuid, 主键)
    - email (文本, 唯一)
    - full_name (文本)
    - created_at (时间戳)
    - updated_at (时间戳)

  ### 2. 企业知识库
  - `company_basic_info` - 企业基础信息
  - `company_qualifications` - 资质信息
  - `company_financial_info` - 财务信息
  - `company_performance` - 业绩信息
  - `company_personnel` - 人员信息
  - `company_historical_bids` - 历史投标文件

  ### 3. 招标文件管理
  - `tender_documents` - 招标文件
  - `tender_requirements` - 招标要求解析

  ### 4. 标书生成
  - `bid_documents` - 标书文件
  - `bid_generation_progress` - 标书生成进度

  ### 5. 标书检查
  - `bid_checks` - 标书检查记录
  - `custom_check_points` - 自定义检查点

  ## 安全性
  - 所有表启用 RLS（行级安全）
  - 为已认证用户创建访问策略
*/

-- 用户表
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  full_name text NOT NULL,
  role text DEFAULT 'user',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all users"
  ON users FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 企业基础信息表
CREATE TABLE IF NOT EXISTS company_basic_info (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name text NOT NULL,
  business_license_url text,
  registration_address text,
  postal_code text,
  contact_person text,
  phone text,
  fax text,
  website text,
  legal_representative text,
  legal_rep_title text,
  legal_rep_phone text,
  technical_director text,
  tech_director_title text,
  tech_director_phone text,
  establishment_date date,
  total_employees integer,
  qualification_level text,
  social_credit_code text,
  registered_capital text,
  bank_name text,
  bank_account text,
  business_scope text,
  created_by uuid REFERENCES users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE company_basic_info ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view company basic info"
  ON company_basic_info FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert company basic info"
  ON company_basic_info FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update company basic info"
  ON company_basic_info FOR UPDATE
  TO authenticated
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);

-- 资质信息表
CREATE TABLE IF NOT EXISTS company_qualifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  qualification_name text NOT NULL,
  certification_body text,
  certificate_number text,
  certification_scope text,
  valid_from date,
  valid_to date,
  file_url text,
  is_expired boolean DEFAULT false,
  created_by uuid REFERENCES users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE company_qualifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view qualifications"
  ON company_qualifications FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert qualifications"
  ON company_qualifications FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update qualifications"
  ON company_qualifications FOR UPDATE
  TO authenticated
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can delete qualifications"
  ON company_qualifications FOR DELETE
  TO authenticated
  USING (auth.uid() = created_by);

-- 财务信息表
CREATE TABLE IF NOT EXISTS company_financial_info (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  year integer NOT NULL,
  revenue numeric,
  profit numeric,
  assets numeric,
  liabilities numeric,
  file_url text,
  created_by uuid REFERENCES users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE company_financial_info ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view financial info"
  ON company_financial_info FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert financial info"
  ON company_financial_info FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update financial info"
  ON company_financial_info FOR UPDATE
  TO authenticated
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can delete financial info"
  ON company_financial_info FOR DELETE
  TO authenticated
  USING (auth.uid() = created_by);

-- 业绩信息表
CREATE TABLE IF NOT EXISTS company_performance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_name text NOT NULL,
  contract_amount numeric,
  contract_date date,
  contract_cover_url text,
  contract_key_page_url text,
  contract_signature_url text,
  invoice_url text,
  invoice_verification_url text,
  client_name text,
  project_description text,
  created_by uuid REFERENCES users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE company_performance ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view performance"
  ON company_performance FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert performance"
  ON company_performance FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update performance"
  ON company_performance FOR UPDATE
  TO authenticated
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can delete performance"
  ON company_performance FOR DELETE
  TO authenticated
  USING (auth.uid() = created_by);

-- 人员信息表
CREATE TABLE IF NOT EXISTS company_personnel (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  id_card text,
  id_card_expiry date,
  phone text,
  address text,
  resume_url text,
  id_card_url text,
  diploma_url text,
  qualification_certificate_url text,
  social_security_url text,
  work_experience text,
  is_id_expired boolean DEFAULT false,
  is_cert_expired boolean DEFAULT false,
  created_by uuid REFERENCES users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE company_personnel ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view personnel"
  ON company_personnel FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert personnel"
  ON company_personnel FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update personnel"
  ON company_personnel FOR UPDATE
  TO authenticated
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can delete personnel"
  ON company_personnel FOR DELETE
  TO authenticated
  USING (auth.uid() = created_by);

-- 历史投标文件表
CREATE TABLE IF NOT EXISTS company_historical_bids (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_name text NOT NULL,
  bid_type text NOT NULL,
  document_url text NOT NULL,
  document_type text,
  parsed_content jsonb,
  created_by uuid REFERENCES users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE company_historical_bids ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view historical bids"
  ON company_historical_bids FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert historical bids"
  ON company_historical_bids FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update historical bids"
  ON company_historical_bids FOR UPDATE
  TO authenticated
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can delete historical bids"
  ON company_historical_bids FOR DELETE
  TO authenticated
  USING (auth.uid() = created_by);

-- 招标文件表
CREATE TABLE IF NOT EXISTS tender_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  document_name text NOT NULL,
  document_url text NOT NULL,
  status text DEFAULT 'uploaded',
  parsed_basic_info jsonb,
  parsed_requirements jsonb,
  parsed_evaluation jsonb,
  parsed_risks jsonb,
  uploaded_by uuid REFERENCES users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE tender_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view tender documents"
  ON tender_documents FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert tender documents"
  ON tender_documents FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = uploaded_by);

CREATE POLICY "Users can update tender documents"
  ON tender_documents FOR UPDATE
  TO authenticated
  USING (auth.uid() = uploaded_by)
  WITH CHECK (auth.uid() = uploaded_by);

CREATE POLICY "Users can delete tender documents"
  ON tender_documents FOR DELETE
  TO authenticated
  USING (auth.uid() = uploaded_by);

-- 标书文件表
CREATE TABLE IF NOT EXISTS bid_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tender_document_id uuid REFERENCES tender_documents(id),
  document_name text NOT NULL,
  document_type text NOT NULL,
  status text DEFAULT 'generating',
  progress integer DEFAULT 0,
  document_url text,
  selected_knowledge jsonb,
  generation_config jsonb,
  created_by uuid REFERENCES users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE bid_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view bid documents"
  ON bid_documents FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert bid documents"
  ON bid_documents FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update bid documents"
  ON bid_documents FOR UPDATE
  TO authenticated
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can delete bid documents"
  ON bid_documents FOR DELETE
  TO authenticated
  USING (auth.uid() = created_by);

-- 自定义检查点表
CREATE TABLE IF NOT EXISTS custom_check_points (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  check_name text NOT NULL,
  check_description text,
  check_type text NOT NULL,
  is_active boolean DEFAULT true,
  created_by uuid REFERENCES users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE custom_check_points ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view check points"
  ON custom_check_points FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert check points"
  ON custom_check_points FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update check points"
  ON custom_check_points FOR UPDATE
  TO authenticated
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can delete check points"
  ON custom_check_points FOR DELETE
  TO authenticated
  USING (auth.uid() = created_by);

-- 标书检查表
CREATE TABLE IF NOT EXISTS bid_checks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bid_document_id uuid REFERENCES bid_documents(id),
  tender_document_id uuid REFERENCES tender_documents(id),
  check_status text DEFAULT 'pending',
  check_results jsonb,
  issues_found integer DEFAULT 0,
  upload_file_url text,
  created_by uuid REFERENCES users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE bid_checks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view bid checks"
  ON bid_checks FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert bid checks"
  ON bid_checks FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update bid checks"
  ON bid_checks FOR UPDATE
  TO authenticated
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can delete bid checks"
  ON bid_checks FOR DELETE
  TO authenticated
  USING (auth.uid() = created_by);

-- 创建索引以提升查询性能
CREATE INDEX IF NOT EXISTS idx_company_qualifications_expiry ON company_qualifications(valid_to);
CREATE INDEX IF NOT EXISTS idx_company_personnel_expiry ON company_personnel(id_card_expiry);
CREATE INDEX IF NOT EXISTS idx_tender_documents_status ON tender_documents(status);
CREATE INDEX IF NOT EXISTS idx_bid_documents_status ON bid_documents(status);
CREATE INDEX IF NOT EXISTS idx_bid_checks_status ON bid_checks(check_status);

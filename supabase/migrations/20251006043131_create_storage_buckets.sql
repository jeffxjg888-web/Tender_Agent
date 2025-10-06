/*
  # 创建文件存储桶

  ## 新建存储桶
  - documents: 用于存储所有文档文件（招标文件、标书、证件等）

  ## 安全策略
  - 允许已认证用户上传文件
  - 允许已认证用户读取文件
  - 公共读取访问
*/

-- 创建文档存储桶
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', true)
ON CONFLICT (id) DO NOTHING;

-- 允许已认证用户上传文件
CREATE POLICY "Authenticated users can upload documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'documents');

-- 允许已认证用户读取文件
CREATE POLICY "Authenticated users can read documents"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'documents');

-- 允许已认证用户删除自己上传的文件
CREATE POLICY "Users can delete own documents"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'documents' AND auth.uid() = owner);

-- 允许公共读取访问
CREATE POLICY "Public can read documents"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'documents');

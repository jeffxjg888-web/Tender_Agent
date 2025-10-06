/*
  # 创建存储桶访问策略

  1. 策略
    - 允许已认证用户上传文件到 documents 桶
    - 允许已认证用户读取 documents 桶中的文件
    - 允许已认证用户更新自己的文件
    - 允许已认证用户删除自己的文件
    - 允许公共访问读取文件

  2. 安全
    - 所有写入操作需要认证
    - 删除和更新操作仅限文件所有者
    - 公共读取访问支持文件分享
*/

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

-- 允许已认证用户更新自己上传的文件
CREATE POLICY "Users can update own documents"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'documents' AND auth.uid() = owner)
WITH CHECK (bucket_id = 'documents' AND auth.uid() = owner);

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

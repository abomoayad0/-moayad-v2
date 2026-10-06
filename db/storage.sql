-- storage.sql
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.

-- ── storage · md5 40ae5ec0cfea6ddb35d5160ff929bc62
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values ('v2-attachments', 'v2-attachments', false, 10485760, '{image/jpeg,image/png,image/webp,application/pdf}'::text[]) on conflict (id) do nothing;

CREATE POLICY v2att_guardian_r ON storage.objects AS PERMISSIVE FOR SELECT TO authenticated
    USING (((bucket_id = 'v2-attachments'::text) AND v2.attachment_guardian_ok(name)));
CREATE POLICY v2att_merit_read ON storage.objects AS PERMISSIVE FOR SELECT TO authenticated
    USING (((bucket_id = 'v2-attachments'::text) AND v2.merit_path_allows(name, false)));
CREATE POLICY v2att_merit_update ON storage.objects AS PERMISSIVE FOR UPDATE TO authenticated
    USING (((bucket_id = 'v2-attachments'::text) AND v2.merit_path_allows(name, true)))
    WITH CHECK (((bucket_id = 'v2-attachments'::text) AND v2.merit_path_allows(name, true)));
CREATE POLICY v2att_merit_write ON storage.objects AS PERMISSIVE FOR INSERT TO authenticated
    WITH CHECK (((bucket_id = 'v2-attachments'::text) AND v2.merit_path_allows(name, true)));
CREATE POLICY v2att_school_rw ON storage.objects AS PERMISSIVE FOR ALL TO authenticated
    USING (((bucket_id = 'v2-attachments'::text) AND (name !~~ 'merit/%'::text) AND v2.attachment_allows(name)))
    WITH CHECK (((bucket_id = 'v2-attachments'::text) AND (name !~~ 'merit/%'::text) AND v2.attachment_allows(name)));


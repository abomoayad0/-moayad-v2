-- v2.assess_tools
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 7b90ea7f31c13ae33cc7951a38195846

CREATE TABLE v2.assess_tools (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid,
    key text NOT NULL,
    label_ar text NOT NULL,
    source_kind text NOT NULL,
    source_ar text,
    active boolean DEFAULT true NOT NULL,
    ord smallint DEFAULT 0 NOT NULL,
    CONSTRAINT assess_tools_pkey PRIMARY KEY (id),
    CONSTRAINT assess_tools_source_kind_check CHECK ((source_kind = ANY (ARRAY['dalil'::text, 'school'::text, 'ijtihad'::text])))
);
CREATE UNIQUE INDEX ux_assess_tools_key ON v2.assess_tools USING btree (school_id, key) NULLS NOT DISTINCT;
ALTER TABLE v2.assess_tools ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.assess_tools IS 'أدواتُ تقويم المهارات — خمسٌ منصوصةٌ في س-٩-ا-١ سياسة ٠٣ ص٢١٧، وكلمةُ «مثل» فيها تجعلها أمثلةً لا حصرًا فللمدرسة أن تزيد.
[بناءُ يدٍ أخرى] بُني ١٠/١٠/٢٠٢٦ ١٨:٠٥ في محادثةِ صفحة المعلّم (الموازي) بإذنٍ من مفرح، لا بيدِ كلودِ البناء. ثمّ أوقف مفرح البناءَ عن الموازي ١٨:٢١ وأمر بوسمِ ما بناه غيرُه ١٨:٢٢. والجدولُ قائمٌ لم يُحذف منه شيء.';

-- v2.form_field_source
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 70dde502b4a2913b3d88047daa9f2277

CREATE TABLE v2.form_field_source (
    form_no smallint NOT NULL,
    field_key text NOT NULL,
    bank_key text,
    compute_kind text,
    by_hand boolean DEFAULT false NOT NULL,
    note_ar text NOT NULL,
    CONSTRAINT form_field_source_pkey PRIMARY KEY (form_no, field_key)
);
ALTER TABLE v2.form_field_source ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.form_field_source IS 'لكلّ حقلٍ نصيٍّ منبعُه مُعلَنًا — والمرآةُ تصرخ بحقلٍ إلزاميٍّ بلا منبع · و«بيدِ المستعمل» إعلانُ حكمٍ يُراجَع لا سكوتٌ عن نقص';

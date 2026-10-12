-- v2.skill_levels
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 d9bce551faeed87f4faf78f792c469d8

CREATE TABLE v2.skill_levels (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid,
    key text NOT NULL,
    label_ar text NOT NULL,
    is_mastered boolean NOT NULL,
    ord smallint DEFAULT 0 NOT NULL,
    source_kind text NOT NULL,
    source_ar text,
    active boolean DEFAULT true NOT NULL,
    CONSTRAINT skill_levels_pkey PRIMARY KEY (id),
    CONSTRAINT skill_levels_source_kind_check CHECK ((source_kind = ANY (ARRAY['dalil'::text, 'school'::text, 'ijtihad'::text])))
);
CREATE UNIQUE INDEX ux_skill_levels_key ON v2.skill_levels USING btree (school_id, key) NULLS NOT DISTINCT;
ALTER TABLE v2.skill_levels ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.skill_levels IS 'مستوياتُ إتقان المهارة. والدليلُ يقول «مراعاةُ لائحة تقويم الطالب» (س-٩-ا-١ سياسة ٠٢ ص٢١٧) ولا يسمّي المستويات، ولائحةُ تقويم الطالب ليست في وثائقنا المرفوعة — فالمستويان أدناه اجتهادٌ معلَنٌ وبيد المدرسة تزيد وتعدّل حتى تُرفع اللائحة.
[بناءُ يدٍ أخرى] بُني ١٠/١٠/٢٠٢٦ ١٨:٠٥ في محادثةِ صفحة المعلّم (الموازي) بإذنٍ من مفرح، لا بيدِ كلودِ البناء. ثمّ أوقف مفرح البناءَ عن الموازي ١٨:٢١ وقصره على كلودِ البناء، وأمر بوسمِ ما بناه غيرُه ١٨:٢٢. والجدولُ قائمٌ لم يُحذف منه شيءٌ، وقراءتُه أصحُّ من قيدِ كلودِ البناء الصلب في v2.skill_marks.level.';

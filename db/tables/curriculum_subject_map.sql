-- v2.curriculum_subject_map
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 41c6b9f561114ed0c79121200b9a001d

CREATE TABLE v2.curriculum_subject_map (
    curriculum_subject_ar text NOT NULL,
    plan_subject_ar text,
    note_ar text NOT NULL,
    set_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT curriculum_subject_map_pkey PRIMARY KEY (curriculum_subject_ar)
);
ALTER TABLE v2.curriculum_subject_map ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.curriculum_subject_map IS 'مطابقةُ أسماء مواد المنهج المنقول بأسماء خطّتنا الدراسيّة. ومن لا نظيرَ له plan_subject_ar فارغٌ ويُعلن سببُه.';

-- v2.teaching_quota
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 826f641fda816885ff2cb3a900465959

CREATE TABLE v2.teaching_quota (
    school_id uuid NOT NULL,
    post_key text NOT NULL,
    min_slots smallint,
    max_slots smallint NOT NULL,
    standby_max smallint,
    note_ar text,
    set_by uuid,
    set_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT teaching_quota_pkey PRIMARY KEY (school_id, post_key)
);
ALTER TABLE v2.teaching_quota ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.teaching_quota IS 'نصابُ الحصص لكلّ صفة — اجتهادُ مدرسةٍ تضبطه من لوحة التحكّم';

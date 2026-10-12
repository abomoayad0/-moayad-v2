-- v2.subject_pairing
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 c62019181864e742249ec6f0b85ae7c9

CREATE TABLE v2.subject_pairing (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    grade smallint,
    subject_ar text NOT NULL,
    mode text DEFAULT 'split'::text NOT NULL,
    max_per_day smallint DEFAULT 1 NOT NULL,
    note_ar text,
    set_by uuid,
    set_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT subject_pairing_pkey PRIMARY KEY (id),
    CONSTRAINT subject_pairing_max_ck CHECK (((max_per_day >= 1) AND (max_per_day <= 4))),
    CONSTRAINT subject_pairing_mode_ck CHECK ((mode = ANY (ARRAY['joined'::text, 'split'::text, 'free'::text])))
);
CREATE UNIQUE INDEX subject_pairing_uq ON v2.subject_pairing USING btree (school_id, COALESCE((grade)::integer, '-1'::integer), subject_ar);
ALTER TABLE v2.subject_pairing ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.subject_pairing IS 'قاعدةُ المادّة في اليوم: متّصلةٌ (حصّتان متجاورتان) · منفصلةٌ (مرّةٌ واحدةٌ في اليوم) · مطلقةٌ (بلا قيد). والافتراضُ منفصلةٌ مرّةً واحدة — فلا تقع المادّةُ مرّتين في يومٍ للفصل نفسه إلّا بطلب المدرسة.';

-- v2.curriculum_term_split
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 95d026c1e256568baa6d4159f55a09e0

CREATE TABLE v2.curriculum_term_split (
    grade smallint NOT NULL,
    subject_ar text NOT NULL,
    term1_until_unit smallint NOT NULL,
    periods_t1 integer,
    periods_t2 integer,
    source_ar text DEFAULT 'مُقرَّرٌ بأمر إدارة النظام'::text NOT NULL,
    note_ar text,
    set_by uuid,
    set_at timestamp with time zone DEFAULT now() NOT NULL,
    confirmed_n integer DEFAULT 0 NOT NULL,
    CONSTRAINT curriculum_term_split_pkey PRIMARY KEY (grade, subject_ar)
);
ALTER TABLE v2.curriculum_term_split ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.curriculum_term_split IS 'حدُّ الفصلين لكلّ صفٍّ ومادّة: الفصلُ الأوّلُ ينتهي بهذي الوحدة. مرجعٌ مشتركٌ لكلّ المدارس — ولا تُقرّره مدرسة. ومصدرُه مُعلَنٌ: منقولٌ من وثيقةٍ أو مُقرَّرٌ بأمر إدارة النظام.';
COMMENT ON COLUMN v2.curriculum_term_split.term1_until_unit IS 'رقمُ آخرِ وحدةٍ في الفصل الأوّل — والقطعُ عند حدّ وحدةٍ لا في وسطها.';
COMMENT ON COLUMN v2.curriculum_term_split.confirmed_n IS 'كم معلّمًا أقرّ هذا الحدَّ — فالمرجعُ يتصحّح بالاستعمال لا بتوقيع إدارةٍ.';

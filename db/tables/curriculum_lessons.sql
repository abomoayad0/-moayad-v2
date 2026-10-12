-- v2.curriculum_lessons
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 28bc876ea6df7bda226df4385aab373d

CREATE TABLE v2.curriculum_lessons (
    id uuid NOT NULL,
    unit_id uuid NOT NULL,
    lesson_no smallint,
    title_ar text NOT NULL,
    periods smallint,
    ord smallint,
    outcomes text[],
    outcomes_source text,
    outcomes_ref text,
    verified boolean DEFAULT false NOT NULL,
    imported_at timestamp with time zone DEFAULT now() NOT NULL,
    kind text,
    kind_source text,
    CONSTRAINT curriculum_lessons_pkey PRIMARY KEY (id),
    CONSTRAINT cl_kind_check CHECK (((kind IS NULL) OR (kind = ANY (ARRAY['lesson'::text, 'exam'::text, 'review'::text, 'intro'::text, 'project'::text, 'activity'::text]))))
);
CREATE INDEX curr_lessons_unit_idx ON v2.curriculum_lessons USING btree (unit_id);
ALTER TABLE v2.curriculum_lessons ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.curriculum_lessons IS 'دروسُ المنهج وعددُ حصصها. والنواتجُ فارغةٌ في أكثرها — verified=false لمن لا مصدرَ له.';
COMMENT ON COLUMN v2.curriculum_lessons.kind IS 'نوعُ البند: lesson درسٌ يُدرَّس · exam اختبار · review مراجعة · intro تهيئة · project مشروع · activity نشاط. وكلُّها تأخذ حصّةً في التوزيع، والوسمُ ليُعرف أنّ البندَ ليس درسًا.';
COMMENT ON COLUMN v2.curriculum_lessons.kind_source IS 'مصدرُ الوسم: «مستنتج من العنوان» أو «مُقرَّرٌ بيد». ولا يُلبس الاستنتاجُ ثوبَ النصّ.';

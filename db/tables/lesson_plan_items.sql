-- v2.lesson_plan_items
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 0271c70568693fdd15bfab660153c536

CREATE TABLE v2.lesson_plan_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    plan_id uuid NOT NULL,
    lesson_id uuid NOT NULL,
    week_no smallint,
    ord smallint DEFAULT 1 NOT NULL,
    periods smallint DEFAULT 1 NOT NULL,
    state text DEFAULT 'planned'::text NOT NULL,
    done_on date,
    periods_used smallint,
    state_by uuid,
    state_at timestamp with time zone,
    state_why text,
    page_from smallint,
    page_to smallint,
    moved_by uuid,
    moved_at timestamp with time zone,
    move_why text,
    note_ar text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    kind_override text,
    kind_by uuid,
    kind_at timestamp with time zone,
    merged_into uuid,
    merged_by uuid,
    merged_at timestamp with time zone,
    merge_why text,
    CONSTRAINT lesson_plan_items_pkey PRIMARY KEY (id),
    CONSTRAINT lesson_plan_items_periods_check CHECK (((periods >= 1) AND (periods <= 10))),
    CONSTRAINT lesson_plan_items_state_check CHECK ((state = ANY (ARRAY['planned'::text, 'done'::text, 'deferred'::text, 'lost'::text]))),
    CONSTRAINT lesson_plan_items_week_no_check CHECK (((week_no >= 1) AND (week_no <= 19))),
    CONSTRAINT lpi_kind_check CHECK (((kind_override IS NULL) OR (kind_override = ANY (ARRAY['lesson'::text, 'exam'::text, 'review'::text, 'intro'::text, 'project'::text, 'activity'::text]))))
);
CREATE INDEX ix_lpi_merged ON v2.lesson_plan_items USING btree (plan_id, merged_into);
CREATE INDEX ix_lpi_state ON v2.lesson_plan_items USING btree (plan_id, state);
CREATE INDEX ix_lpi_week ON v2.lesson_plan_items USING btree (plan_id, week_no, ord);
CREATE UNIQUE INDEX ux_lpi_lesson ON v2.lesson_plan_items USING btree (plan_id, lesson_id);
ALTER TABLE v2.lesson_plan_items ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.lesson_plan_items IS 'سطرٌ لكلّ درسٍ في الخطّة: أسبوعُه وترتيبُه وحصصُه وحالتُه وصفحاتُه من الكتاب. وهو ما لم يكن في النظام القديم — فلم يملك المعلّمُ نقلَ درسٍ إلى أسبوعٍ آخر.';
COMMENT ON COLUMN v2.lesson_plan_items.week_no IS 'أسبوعُ الفصل ١..١٩ — ولا يُوضع درسٌ في أسبوع اختبار. ونصُّ الدليل: «يوزّع المعلّمُ الوحداتَ على فصولِ وأسابيعِ السنة الدراسيّة» ص٢٠٧.';
COMMENT ON COLUMN v2.lesson_plan_items.state IS 'planned مخطَّطٌ · done أُنجز · deferred رُحّل فيظهر في الأسبوع التالي · lost فات. والحالاتُ الثلاثُ الأخيرةُ منقولةٌ من النظام القديم وكانت أنفعَ ما فيه.';
COMMENT ON COLUMN v2.lesson_plan_items.page_from IS 'صفحةُ الدرس في كتاب الطالب — تُضاف متى رُفعت الكتب، ويعمل التوزيعُ بلا صفحاتٍ قبلها.';
COMMENT ON COLUMN v2.lesson_plan_items.move_why IS 'سببُ نقل الدرس من أسبوعٍ إلى أسبوع — ولا يُنقل درسٌ بلا سبب، فالتوزيعُ يُعدَّل بأثرِ الإنجاز وتحليلِ النواتج لا بالمزاج (نصُّ الخطوة ٤ ص٢٠٧).';
COMMENT ON COLUMN v2.lesson_plan_items.kind_override IS 'وسمُ المعلّم لنوع البند في خطّته — يُرجَّح على وسم المنهج، والأصلُ باقٍ.';
COMMENT ON COLUMN v2.lesson_plan_items.merged_into IS 'دُمج هذا البندُ في بندٍ آخرَ (lesson_id المضيف) — يُدرَّسان في حصّةٍ واحدة. والاثنان باقيان في السجلّ، وتُحسب حصّةُ المضيف وحدَها.';

-- v2.card_events
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 75cd408efed820db056fa7a9d428a033

CREATE TABLE v2.card_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    session_id uuid,
    school_id uuid NOT NULL,
    year_id uuid,
    term_no smallint NOT NULL,
    student_id uuid NOT NULL,
    person_id uuid NOT NULL,
    by_role_ar text,
    on_date date DEFAULT CURRENT_DATE NOT NULL,
    period_no smallint,
    slot_id uuid,
    kind text NOT NULL,
    code text,
    title_ar text NOT NULL,
    polarity text,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    note_ar text,
    place_ar text,
    undone_at timestamp with time zone,
    undone_by uuid,
    undo_reason text,
    linked_target text,
    linked_id uuid,
    linked_at timestamp with time zone,
    link_note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_test boolean DEFAULT false NOT NULL,
    class_session uuid,
    CONSTRAINT card_events_pkey PRIMARY KEY (id),
    CONSTRAINT card_events_kind_check CHECK ((kind = ANY (ARRAY['practice'::text, 'health_view'::text, 'note'::text]))),
    CONSTRAINT card_events_polarity_check CHECK ((polarity = ANY (ARRAY['positive'::text, 'negative'::text, 'neutral'::text])))
);
CREATE INDEX ix_card_events_person ON v2.card_events USING btree (person_id, on_date DESC);
CREATE INDEX ix_card_events_student ON v2.card_events USING btree (student_id, on_date DESC) WHERE (undone_at IS NULL);
CREATE INDEX ix_card_events_unlinked ON v2.card_events USING btree (school_id, created_at) WHERE ((linked_at IS NULL) AND (undone_at IS NULL));
ALTER TABLE v2.card_events ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.card_events IS 'أحداثُ بطاقة الطالب — موضعُ الحقيقة لما يقع داخل الحصّة. مستقلّةٌ بقرار مفرح ١١/١٠/٢٠٢٦، وخاناتُ الربط الثلاثُ مُعلنةٌ: فراغُها يعني أنّ الحدثَ لم يُرفع إلى المحرّك الرسميّ بعد — ويكشفه الجردُ.';
COMMENT ON COLUMN v2.card_events.kind IS 'ثلاثةٌ فقط. والمخالفةُ في محرّك الدليل · والواجبُ في class_work · والخروجُ في class_exits · والدورُ في class_role_holders.';
COMMENT ON COLUMN v2.card_events.class_session IS 'جلسةُ الحصّة التي وقع فيها الحدث — تُفتح تلقائيًّا إن لم تكن مفتوحة.';

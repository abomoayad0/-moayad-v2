-- v2.card_views
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 6ada7add2cfdca8241ef0ce7c9c4e030

CREATE TABLE v2.card_views (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    student_id uuid NOT NULL,
    by_person uuid NOT NULL,
    by_role_ar text,
    kind text NOT NULL,
    on_date date DEFAULT CURRENT_DATE NOT NULL,
    period_no smallint,
    at_ts timestamp with time zone DEFAULT now() NOT NULL,
    own_device boolean,
    note_ar text,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT card_views_pkey PRIMARY KEY (id),
    CONSTRAINT card_views_kind_check CHECK ((kind = ANY (ARRAY['health'::text, 'social'::text, 'deputy'::text, 'counselor'::text])))
);
CREATE INDEX ix_card_views_person ON v2.card_views USING btree (by_person, on_date);
CREATE INDEX ix_card_views_student ON v2.card_views USING btree (student_id, at_ts DESC);
ALTER TABLE v2.card_views ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.card_views IS 'اطّلاعُ المعلّم على المحجوب في بطاقة الطالب — صحّيٌّ أو اجتماعيٌّ أو عملُ وكيلٍ أو موجّه. يُكتب حين يكون مفتاحُ card_health_log مُشغَّلًا، فتصدق عبارةُ «يُسجَّل اطّلاعك».';
COMMENT ON COLUMN v2.card_views.own_device IS 'أقرّ المعلّمُ أنّ الجهازَ خاصٌّ به وليس موصولًا بالعارض.';

-- v2.absence_ladder_items
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 d1830b2259b0e7f60afab80b99e54d01

CREATE TABLE v2.absence_ladder_items (
    id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
    ladder_id integer NOT NULL,
    ord smallint NOT NULL,
    kind text NOT NULL,
    text_ar text NOT NULL,
    owner_role text NOT NULL,
    origin text DEFAULT 'الدليل'::text NOT NULL,
    evidence_kind text,
    CONSTRAINT absence_ladder_items_pkey PRIMARY KEY (id),
    CONSTRAINT absence_ladder_items_ladder_id_ord_key UNIQUE (ladder_id, ord),
    CONSTRAINT absence_ladder_items_kind_check CHECK ((kind = ANY (ARRAY['counselor'::text, 'summon_guardian'::text, 'assess_services'::text, 'update_plan'::text, 'pledge'::text, 'committee'::text, 'awareness_session'::text, 'notify_guardian'::text, 'warn_guardian'::text, 'external_report'::text, 'follow_up'::text, 'learning_plan'::text, 'other'::text]))),
    CONSTRAINT absence_ladder_items_origin_check CHECK ((origin = ANY (ARRAY['الدليل'::text, 'البناء'::text, 'قرار مفرح'::text]))),
    CONSTRAINT absence_ladder_items_text_ar_check CHECK ((btrim(text_ar) <> ''::text))
);
ALTER TABLE v2.absence_ladder_items ENABLE ROW LEVEL SECURITY;
COMMENT ON COLUMN v2.absence_ladder_items.evidence_kind IS 'نوع الإثبات الذي تُغلق به المهمة. لا تُغلق مهمة غياب بزرّ «نُفّذت» وحده.';

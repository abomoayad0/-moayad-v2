-- v2.build_journal
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 f71433d93a426a75bf3bd24a0ac4020c

CREATE TABLE v2.build_journal (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    kind text NOT NULL,
    area_ar text NOT NULL,
    title_ar text NOT NULL,
    text_ar text NOT NULL,
    said_by text DEFAULT 'مفرح'::text NOT NULL,
    source_ar text,
    state text DEFAULT 'active'::text NOT NULL,
    closed_ar text,
    closed_at timestamp with time zone,
    ord integer DEFAULT 100 NOT NULL,
    at timestamp with time zone DEFAULT now() NOT NULL,
    by_person uuid,
    CONSTRAINT build_journal_pkey PRIMARY KEY (id),
    CONSTRAINT build_journal_kind_check CHECK ((kind = ANY (ARRAY['rule'::text, 'decision'::text, 'deferred'::text, 'gap'::text, 'mistake'::text]))),
    CONSTRAINT build_journal_state_check CHECK ((state = ANY (ARRAY['active'::text, 'done'::text, 'dropped'::text])))
);
CREATE INDEX ix_journal_area ON v2.build_journal USING btree (area_ar, state);
CREATE INDEX ix_journal_kind ON v2.build_journal USING btree (kind, state, ord);
ALTER TABLE v2.build_journal ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.build_journal IS 'سجلُّ البناء: القواعدُ والقرارات والمؤجّلاتُ والثغراتُ والأخطاء. داخليٌّ — يُقرأ لإدارة النظام وإدارة المدرسة، ولا يُحذف منه صفّ.';
COMMENT ON COLUMN v2.build_journal.kind IS 'rule قاعدةٌ حاكمة · decision قرارٌ في ميدان · deferred مؤجّلةٌ محفوظة · gap ثغرةٌ معروفة · mistake خطأٌ وقع ويُتّقى.';
COMMENT ON COLUMN v2.build_journal.state IS 'active قائمةٌ تُراعى · done أُنجزت · dropped أُلغيت بأمر. ولا يُحذف صفٌّ — يُقفل بسببه.';

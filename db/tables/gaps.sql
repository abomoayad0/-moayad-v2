-- v2.gaps
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 63e714de9ce27e61662f1f21abce0286

CREATE TABLE v2.gaps (
    gap_no integer GENERATED ALWAYS AS IDENTITY NOT NULL,
    title text NOT NULL,
    card_code text,
    step_no integer,
    guide_code text NOT NULL,
    page_ref integer,
    established text NOT NULL,
    likely_source text,
    status text DEFAULT 'open'::text NOT NULL,
    closed_by text,
    closed_page integer,
    opened_at timestamp with time zone DEFAULT now() NOT NULL,
    closed_at timestamp with time zone,
    pattern text,
    origin text DEFAULT 'الدليل'::text NOT NULL,
    closed_ref text,
    CONSTRAINT gaps_pkey PRIMARY KEY (gap_no),
    CONSTRAINT gaps_close_needs_proof CHECK (((status <> 'closed'::text) OR ((btrim(COALESCE(closed_by, ''::text)) <> ''::text) AND ((closed_page IS NOT NULL) OR (btrim(COALESCE(closed_ref, ''::text)) <> ''::text))))),
    CONSTRAINT gaps_established_check CHECK ((btrim(established) <> ''::text)),
    CONSTRAINT gaps_origin_check CHECK ((origin = ANY (ARRAY['الدليل'::text, 'قرار مفرح'::text, 'البناء'::text]))),
    CONSTRAINT gaps_status_check CHECK ((status = ANY (ARRAY['open'::text, 'searching'::text, 'sourced'::text, 'decided'::text]))),
    CONSTRAINT gaps_step_needs_card CHECK (((step_no IS NULL) OR (card_code IS NOT NULL))),
    CONSTRAINT gaps_title_check CHECK ((btrim(title) <> ''::text))
);
CREATE INDEX gaps_card_idx ON v2.gaps USING btree (card_code);
CREATE INDEX gaps_pattern_idx ON v2.gaps USING btree (pattern);
CREATE INDEX gaps_status_idx ON v2.gaps USING btree (status);
ALTER TABLE v2.gaps ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.gaps IS 'سجل النواقص: ما نقص من سند في الأدلة، وأين ظهر، وبماذا أُغلق. لا يُغلق بند إلا بوثيقة مسماة أو قرار مكتوب.';
COMMENT ON COLUMN v2.gaps.pattern IS 'اسم العلة المتكررة، يجمع النواقص المتشابهة ليُعرف الثقيل من العابر. فارغ = حالة منفردة.';
COMMENT ON COLUMN v2.gaps.origin IS 'مصدر ما في البند: الدليل = نص وزاري منقول. قرار مفرح = قرار من صاحب القرار. البناء = إضافة من بناء النظام. لا يُخلط قرار مفرح بنص الوزارة.';
COMMENT ON COLUMN v2.gaps.closed_ref IS 'مرجع الإغلاق حين لا يكون صفحةً مرقّمة في دليل: رقم تقرير رسمي، أو قرار، أو وثيقة من جهة. يقوم مقام closed_page ولا يُغني عن closed_by.';

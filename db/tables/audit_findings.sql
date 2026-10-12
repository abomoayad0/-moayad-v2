-- v2.audit_findings
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 7e41746828ed4be29dfdc43639b23567

CREATE TABLE v2.audit_findings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    check_key text NOT NULL,
    object_ar text NOT NULL,
    detail_ar text,
    severity text NOT NULL,
    first_seen timestamp with time zone DEFAULT now() NOT NULL,
    last_seen timestamp with time zone DEFAULT now() NOT NULL,
    seen_n integer DEFAULT 1 NOT NULL,
    resolved_at timestamp with time zone,
    waived_at timestamp with time zone,
    waived_by uuid,
    waive_why text,
    CONSTRAINT audit_findings_pkey PRIMARY KEY (id),
    CONSTRAINT audit_findings_waive_ck CHECK (((waived_at IS NULL) OR (btrim(COALESCE(waive_why, ''::text)) <> ''::text)))
);
CREATE INDEX audit_findings_open_ix ON v2.audit_findings USING btree (check_key) WHERE ((resolved_at IS NULL) AND (waived_at IS NULL));
CREATE UNIQUE INDEX audit_findings_uq ON v2.audit_findings USING btree (check_key, object_ar);
ALTER TABLE v2.audit_findings ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.audit_findings IS 'ما كشفه الجردُ: لكلّ خللٍ أوّلُ ظهورٍ وآخرُ ظهورٍ وعددُ مرّاته، ومتى أُصلح، ومن أسقطه بسببٍ مكتوب. ولا يُحذف منه صفّ — فالخللُ الراجعُ يُعرف أنّه رجع.';

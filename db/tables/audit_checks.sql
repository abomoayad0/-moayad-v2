-- v2.audit_checks
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 02a25138a2e660c840315edd278c6b76

CREATE TABLE v2.audit_checks (
    key text NOT NULL,
    label_ar text NOT NULL,
    why_ar text NOT NULL,
    severity text DEFAULT 'انتبه'::text NOT NULL,
    source_ar text,
    active boolean DEFAULT true NOT NULL,
    ord smallint DEFAULT 50 NOT NULL,
    CONSTRAINT audit_checks_pkey PRIMARY KEY (key),
    CONSTRAINT audit_checks_sev_ck CHECK ((severity = ANY (ARRAY['خلل'::text, 'انتبه'::text])))
);
ALTER TABLE v2.audit_checks ENABLE ROW LEVEL SECURITY;

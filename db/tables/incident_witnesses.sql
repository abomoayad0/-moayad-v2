-- v2.incident_witnesses
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 37bf84b03082c879a0e45a9c3f0fb972

CREATE TABLE v2.incident_witnesses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    record_id uuid NOT NULL,
    ord smallint NOT NULL,
    full_name text NOT NULL,
    job_ar text,
    assigned_work_ar text,
    signed boolean DEFAULT false NOT NULL,
    signed_at timestamp with time zone,
    CONSTRAINT incident_witnesses_pkey PRIMARY KEY (id),
    CONSTRAINT incident_witnesses_record_id_ord_key UNIQUE (record_id, ord),
    CONSTRAINT incident_witnesses_full_name_check CHECK ((btrim(full_name) <> ''::text)),
    CONSTRAINT incident_witnesses_ord_check CHECK (((ord >= 1) AND (ord <= 7)))
);
ALTER TABLE v2.incident_witnesses ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.incident_witnesses IS 'شهود الواقعة — محضر ضبط واقعة ص68: سبعة صفوف، لكل شاهد الاسم والوظيفة والعمل المسند إليه والتوقيع.';

-- v2.violence_cases
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 451db6a96e2437a72e26932aa343e13d

CREATE TABLE v2.violence_cases (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid NOT NULL,
    victim_id uuid NOT NULL,
    source_kind text NOT NULL,
    offender_student uuid,
    offender_note text,
    type_key text NOT NULL,
    on_date date NOT NULL,
    description_ar text,
    actions_ar text,
    recommendations_ar text,
    followup_ar text,
    status text DEFAULT 'open'::text NOT NULL,
    referred_to_protection boolean DEFAULT false NOT NULL,
    referred_on date,
    record_id uuid,
    kept_by uuid,
    kept_role text DEFAULT 'الموجه الطلابي'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT violence_cases_pkey PRIMARY KEY (id),
    CONSTRAINT violence_cases_source_kind_check CHECK ((source_kind = ANY (ARRAY['peer'::text, 'teacher_or_equiv'::text, 'family'::text, 'other'::text]))),
    CONSTRAINT violence_cases_status_check CHECK ((status = ANY (ARRAY['open'::text, 'treated'::text, 'ongoing'::text, 'referred'::text])))
);
CREATE INDEX vc_school_idx ON v2.violence_cases USING btree (school_id, year_id);
ALTER TABLE v2.violence_cases ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.violence_cases IS 'ملف حالات العنف والتنمر المدرسي. نموذج (3) في رفق ص46، وملحوظته: «هذه الاستمارة لاستخدام المدرسة فقط وتحفظ في ملف (حالات العنف والتنمر المدرسي) لدى الموجه الطلابي». وهو ملف غير ملف النماذج الموقَّعة لدى وكيل شؤون الطلبة.';

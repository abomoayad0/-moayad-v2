-- v2.day_closures
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 ae4812306c60869e9dc5347721a5eeca

CREATE TABLE v2.day_closures (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    on_date date NOT NULL,
    closed_at timestamp with time zone DEFAULT now() NOT NULL,
    closed_by uuid,
    students_n integer,
    absent_n integer,
    late_n integer,
    derived_n integer,
    reopened_at timestamp with time zone,
    reopened_by uuid,
    reopen_reason text,
    reclosed_at timestamp with time zone,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT day_closures_pkey PRIMARY KEY (id),
    CONSTRAINT day_closures_school_id_on_date_key UNIQUE (school_id, on_date),
    CONSTRAINT reopen_needs_reason CHECK (((reopened_at IS NULL) OR (btrim(COALESCE(reopen_reason, ''::text)) <> ''::text)))
);
ALTER TABLE v2.day_closures ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.day_closures IS 'إقفال اليوم. لا حسم ولا سلّم ولا إحالة قبله. وإعادة الفتح لا تُمحى ولا تقع بلا سبب مكتوب.';

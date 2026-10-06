-- v2.student_permissions
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 9827db03938da09e0f7460a348b63cd4

CREATE TABLE v2.student_permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid NOT NULL,
    term_no smallint NOT NULL,
    student_id uuid NOT NULL,
    on_date date NOT NULL,
    out_at time without time zone NOT NULL,
    back_at time without time zone,
    returned boolean DEFAULT false NOT NULL,
    reason_ar text NOT NULL,
    requested_by text NOT NULL,
    guardian_id uuid,
    approved_by uuid,
    approved_at timestamp with time zone DEFAULT now() NOT NULL,
    periods_out smallint[],
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT student_permissions_pkey PRIMARY KEY (id),
    CONSTRAINT student_permissions_reason_ar_check CHECK ((btrim(reason_ar) <> ''::text)),
    CONSTRAINT student_permissions_requested_by_check CHECK ((requested_by = ANY (ARRAY['guardian'::text, 'student'::text, 'school'::text])))
);
CREATE INDEX sp_day_idx ON v2.student_permissions USING btree (school_id, on_date);
ALTER TABLE v2.student_permissions ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.student_permissions IS 'استئذان الطالب — بطاقته س-٦-ا٢. لا يُحسب غياباً ولا تأخراً ولا يدخل في مواظبة ولا سلوك. والحصص التي خرج فيها تُوسم permitted_out ولا تُعدّ هروباً.';

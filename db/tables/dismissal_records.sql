-- v2.dismissal_records
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 158c1e05229e99613e82d4ad0c90e642

CREATE TABLE v2.dismissal_records (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid NOT NULL,
    term_no smallint NOT NULL,
    student_id uuid NOT NULL,
    on_date date NOT NULL,
    left_at time without time zone,
    minutes_after smallint NOT NULL,
    threshold text NOT NULL,
    reason_ar text,
    recorded_by uuid,
    recorded_role text DEFAULT 'المناوب'::text NOT NULL,
    guardian_notified boolean DEFAULT false NOT NULL,
    action_taken text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT dismissal_records_pkey PRIMARY KEY (id),
    CONSTRAINT dismissal_records_student_id_on_date_key UNIQUE (student_id, on_date),
    CONSTRAINT dismissal_records_threshold_check CHECK ((threshold = ANY (ARRAY['census_15'::text, 'action_30'::text])))
);
CREATE INDEX dis_day_idx ON v2.dismissal_records USING btree (school_id, on_date);
ALTER TABLE v2.dismissal_records ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.dismissal_records IS 'تأخر الانصراف. ض03: يُحصر المتأخرون بعد نهاية الدوام بـ15 دقيقة من قبل المناوب. ض06: عند التأخر بعد نهاية الدوام بـ30 دقيقة يُتخذ الإجراء المناسب بناء على قواعد العمل.';

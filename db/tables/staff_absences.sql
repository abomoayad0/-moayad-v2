-- v2.staff_absences
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 6b4530b56bff4f316ca048fd2e610946

CREATE TABLE v2.staff_absences (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    person_id uuid NOT NULL,
    on_date date NOT NULL,
    from_period smallint,
    to_period smallint,
    reason_key text NOT NULL,
    note_ar text,
    recorded_by uuid,
    recorded_at timestamp with time zone DEFAULT now() NOT NULL,
    voided_at timestamp with time zone,
    voided_by uuid,
    void_why text,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT staff_absences_pkey PRIMARY KEY (id),
    CONSTRAINT staff_absences_periods_ck CHECK (((from_period IS NULL) OR (to_period IS NULL) OR (to_period >= from_period)))
);
CREATE INDEX staff_absences_day_ix ON v2.staff_absences USING btree (school_id, on_date);
CREATE UNIQUE INDEX staff_absences_live_uq ON v2.staff_absences USING btree (school_id, person_id, on_date) WHERE (voided_at IS NULL);
ALTER TABLE v2.staff_absences ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.staff_absences IS 'غيابُ الكادر — مدخلُ الصباح الذي يُبنى عليه توزيعُ الاحتياط. لا نصَّ له في س-٨-ا-١، وهو لازمٌ لتشغيل الاحتياط المعتمد في الجدول.';

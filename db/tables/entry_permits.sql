-- v2.entry_permits
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 124c86603f78741302d9944a99ede012

CREATE TABLE v2.entry_permits (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    student_id uuid NOT NULL,
    on_date date NOT NULL,
    arrived_at time without time zone NOT NULL,
    minutes_late smallint NOT NULL,
    decision text NOT NULL,
    issued_by uuid,
    issued_at timestamp with time zone DEFAULT now() NOT NULL,
    note text,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT entry_permits_pkey PRIMARY KEY (id),
    CONSTRAINT entry_permits_student_id_on_date_key UNIQUE (student_id, on_date),
    CONSTRAINT entry_permits_decision_check CHECK ((decision = ANY (ARRAY['enter_class'::text, 'to_counselor'::text])))
);
ALTER TABLE v2.entry_permits ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.entry_permits IS 'إذن الموافقة. ض٠٥ من س-٦-ا١: «في حال التأخر الصباحي يتم إدخال الطالب إلى فصله مع إذن الموافقة أو تحويله إلى الموجه الطلابي مباشرة». وهو ما يفرّق بين المتأخر والهارب في سجل الحصة.';

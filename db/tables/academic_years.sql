-- v2.academic_years
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 3805eae8f234e02279193f0b8914b7e7

CREATE TABLE v2.academic_years (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    name text NOT NULL,
    starts_on date NOT NULL,
    ends_on date NOT NULL,
    is_current boolean DEFAULT false NOT NULL,
    status text DEFAULT 'open'::text NOT NULL,
    closed_on date,
    closed_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT academic_years_pkey PRIMARY KEY (id),
    CONSTRAINT academic_years_school_id_name_key UNIQUE (school_id, name),
    CONSTRAINT academic_years_check CHECK ((ends_on > starts_on)),
    CONSTRAINT academic_years_check1 CHECK (((status = 'open'::text) OR (closed_on IS NOT NULL))),
    CONSTRAINT academic_years_status_check CHECK ((status = ANY (ARRAY['open'::text, 'closed'::text])))
);
CREATE UNIQUE INDEX academic_years_one_current ON v2.academic_years USING btree (school_id) WHERE is_current;
ALTER TABLE v2.academic_years ENABLE ROW LEVEL SECURITY;

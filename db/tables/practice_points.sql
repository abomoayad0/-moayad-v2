-- v2.practice_points
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 4be53ab9fa5930b426f70f514760b27c

CREATE TABLE v2.practice_points (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid,
    term_no smallint,
    student_id uuid NOT NULL,
    points numeric(5,2) NOT NULL,
    record_id uuid,
    reason text NOT NULL,
    is_test boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT practice_points_pkey PRIMARY KEY (id)
);
CREATE INDEX pp_student_idx ON v2.practice_points USING btree (student_id, year_id);
ALTER TABLE v2.practice_points ENABLE ROW LEVEL SECURITY;

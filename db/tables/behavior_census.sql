-- v2.behavior_census
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 2f3847bce09733417fe3aa4598577b61

CREATE TABLE v2.behavior_census (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    student_id uuid NOT NULL,
    task_id uuid,
    record_id uuid,
    assigned_to uuid,
    assigned_by uuid,
    assigned_at timestamp with time zone DEFAULT now() NOT NULL,
    days smallint DEFAULT 5 NOT NULL,
    due_on date,
    state text DEFAULT 'مكلَّف'::text NOT NULL,
    returned_why text,
    positives text,
    negatives text,
    causes text,
    suggestion text,
    filed_at timestamp with time zone,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT behavior_census_pkey PRIMARY KEY (id),
    CONSTRAINT behavior_census_state_check CHECK ((state = ANY (ARRAY['مكلَّف'::text, 'مكتمل'::text, 'مُعاد'::text])))
);
CREATE INDEX ix_bc_to ON v2.behavior_census USING btree (assigned_to, state);
ALTER TABLE v2.behavior_census ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.behavior_census IS 'حصرُ السلوكيّات — CONDUCT-1447-OFF ص20، الإجراء الثاني. الوكيلُ يكلّف من يلاحظ الطالبَ، والمكلَّفُ يحصر الإيجابيَّ والسلبيَّ ومسبّباتِه';

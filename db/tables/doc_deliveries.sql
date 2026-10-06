-- v2.doc_deliveries
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 6f1250f8c3a6a6842e37cf645bef2eb1

CREATE TABLE v2.doc_deliveries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    doc_id uuid NOT NULL,
    printed_at timestamp with time zone,
    printed_by uuid,
    handed_at timestamp with time zone,
    handed_by uuid,
    handed_to text,
    student_ack_at timestamp with time zone,
    due_back_on date,
    returned_at timestamp with time zone,
    returned_by uuid,
    scan_ref text,
    status text DEFAULT 'printed'::text NOT NULL,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT doc_deliveries_pkey PRIMARY KEY (id),
    CONSTRAINT doc_deliveries_handed_to_check CHECK ((handed_to = ANY (ARRAY['student'::text, 'guardian_in_person'::text, 'courier'::text]))),
    CONSTRAINT doc_deliveries_status_check CHECK ((status = ANY (ARRAY['printed'::text, 'handed'::text, 'acknowledged'::text, 'returned'::text, 'overdue'::text, 'lost'::text])))
);
CREATE INDEX dd_doc_idx ON v2.doc_deliveries USING btree (doc_id);
ALTER TABLE v2.doc_deliveries ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.doc_deliveries IS 'سلسلة إثبات تسليم الورق: طُبع ← سُلّم ← أقرّ الطالب بالاستلام ← أُعيد موقّعًا ← صورة. وكل لحظة بوقتها وفاعلها.';

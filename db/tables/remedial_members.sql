-- v2.remedial_members
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 8fd0918fabef2e6280a5d4f67ed7b764

CREATE TABLE v2.remedial_members (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    plan_id uuid NOT NULL,
    student_id uuid NOT NULL,
    added_by uuid,
    added_at timestamp with time zone DEFAULT now() NOT NULL,
    improved boolean,
    out_why text,
    removed_at timestamp with time zone,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT remedial_members_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX ux_remedial_members_live ON v2.remedial_members USING btree (plan_id, student_id) WHERE (removed_at IS NULL);
ALTER TABLE v2.remedial_members ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.remedial_members IS 'طلّابُ الخطّة العلاجيّة الجماعيّة — «توزيعُ الطلّاب إلى مجموعاتٍ حسب مخرجات التصنيف» س-٩-ا-٢ خطوة ٠١ ص٢٢٥. وسقفُ المجموعة من مرجع الأرقام remedial_group_max وهو قرارُ مدرسة.';

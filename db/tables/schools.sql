-- v2.schools
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 f415395ea205f8bcd19c4ae71d71f44b

CREATE TABLE v2.schools (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name_ar text NOT NULL,
    stage text NOT NULL,
    category text NOT NULL,
    classes_count integer NOT NULL,
    students_count integer NOT NULL,
    structure_code text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id uuid NOT NULL,
    calendar_scope text,
    test_mode boolean DEFAULT false NOT NULL,
    CONSTRAINT schools_pkey PRIMARY KEY (id),
    CONSTRAINT schools_classes_count_check CHECK ((classes_count > 0)),
    CONSTRAINT schools_students_count_check CHECK ((students_count >= 0))
);
ALTER TABLE v2.schools ENABLE ROW LEVEL SECURITY;
COMMENT ON COLUMN v2.schools.calendar_scope IS 'نطاق التقويم الذي تتبعه المدرسة. يُعرف من المدرسة عند تسجيلها ولا يُفترض — فالمنطقة الغربية (مكة والمدينة وجدة والطائف) تزيد أسبوعاً بحكم الحج.';
COMMENT ON COLUMN v2.schools.test_mode IS 'وضع التجربة. كل ما يُرصد والمدرسة فيه يُوسم is_test ويُستثنى من التقارير، ويُمحى بأمر واحد. ويُطفأ متى تحقّق النجاح فيصير الرصد حقيقيًّا.';

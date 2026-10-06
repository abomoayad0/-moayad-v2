-- v2.report_filers
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 f721e1a7b2ae74b91b58d535b31d4d38

CREATE TABLE v2.report_filers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    record_id uuid,
    full_name text NOT NULL,
    national_id text,
    nationality_ar text,
    phone text,
    mobile text,
    address_ar text,
    filed_at timestamp with time zone DEFAULT now() NOT NULL,
    note text,
    CONSTRAINT report_filers_pkey PRIMARY KEY (id),
    CONSTRAINT report_filers_national_id_check CHECK (((national_id IS NULL) OR (national_id ~ '^[0-9]{10}$'::text)))
);
ALTER TABLE v2.report_filers ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.report_filers IS 'بيانات الجهة المبلّغة في نموذج الإبلاغ عن حالة إيذاء (ص70): اسم المبلغ · رقم السجل المدني · الجنسية · رقم الهاتف · رقم الجوال · العنوان.';

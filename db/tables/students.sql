-- v2.students
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 163be1b6cabb5510ee592dd8c1b14b6e

CREATE TABLE v2.students (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id uuid NOT NULL,
    school_id uuid NOT NULL,
    student_no text NOT NULL,
    national_id text,
    full_name text NOT NULL,
    nationality text,
    birth_date date,
    health_notes text,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    birth_date_hijri text,
    joined_hijri text,
    reg_status text,
    doc_type text,
    doc_issuer text,
    doc_issued_hijri text,
    passport_no text,
    full_name_en text,
    source_ref text,
    sex text,
    marital_status_ar text,
    address_ar text,
    student_phone text,
    user_id uuid,
    portal_active boolean DEFAULT false NOT NULL,
    CONSTRAINT students_pkey PRIMARY KEY (id),
    CONSTRAINT students_school_id_student_no_key UNIQUE (school_id, student_no),
    CONSTRAINT students_full_name_check CHECK ((btrim(full_name) <> ''::text)),
    CONSTRAINT students_national_id_check CHECK (((national_id IS NULL) OR (national_id ~ '^[0-9]{10}$'::text))),
    CONSTRAINT students_sex_check CHECK ((sex = ANY (ARRAY['ذكر'::text, 'أنثى'::text]))),
    CONSTRAINT students_status_check CHECK ((status = ANY (ARRAY['active'::text, 'transferred'::text, 'graduated'::text, 'withdrawn'::text, 'deceased'::text]))),
    CONSTRAINT students_student_no_check CHECK ((student_no ~ '^[0-9]{9}$'::text))
);
CREATE UNIQUE INDEX ux_students_user ON v2.students USING btree (user_id) WHERE (user_id IS NOT NULL);
ALTER TABLE v2.students ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.students IS 'الطالب: ما يثبت ولا يتغير بالسنة. رقم الطالب تسع خانات وهو معرّف الدخول، فريد داخل المدرسة.';
COMMENT ON COLUMN v2.students.health_notes IS 'الحالات الصحية. سند فتحها لمنسوبي المدرسة: دليل إجراءات العمل PROC-1446-OFF، خطوة 04 من إجراء إعداد خطة تنفيذ برامج التوجيه الطلابي: «التعميم على جميع العاملين والتوجيه الصحي في المدرسة بذوي الحالات المرضية وضرورة مراعاتهم» — ومسؤولها الوكيل لشؤون الطلاب.';
COMMENT ON COLUMN v2.students.doc_type IS 'نوع وثيقة الهوية كما في نور: رقم الهوية · رخصة اقامه · جواز سفر.';
COMMENT ON COLUMN v2.students.source_ref IS 'مرجع المصدر: رقم تقرير نور وتاريخه، لإثبات من أين جاءت البيانات.';
COMMENT ON COLUMN v2.students.sex IS 'الجنس — منصوص في نموذجي الإبلاغ (CONDUCT ص70 · RIFQ ص47) خانةً مفتوحة. والقيمتان من البناء لا من الدليل.';
COMMENT ON COLUMN v2.students.marital_status_ar IS 'الحالة الاجتماعية — خانة مفتوحة بلا قائمة قيم، كما تركها الدليل. وردت في موضعين فقط: نموذج الإبلاغ عن الإيذاء CONDUCT-1447-OFF ص70، ونموذج الإبلاغ عن العنف RIFQ-1445-OFF ص47 — وفي كليهما سطر يُملأ بخط اليد بلا خيارات ولا تعريف. ولم يُخترع لها قيم. 🔎 تنتظر نموذجها إن وُجد في دليل التوجيه الطلابي أو الملف الصحي.';
COMMENT ON COLUMN v2.students.address_ar IS 'نموذج الإبلاغ عن حالة إيذاء CONDUCT-1447-OFF ص70 يطلب للطالب: الاسم · العمر · الحالة الاجتماعية · الجنس · رقم السجل المدني · الجنسية · رقم الهاتف · رقم الجوال · العنوان.';
COMMENT ON COLUMN v2.students.user_id IS 'حسابُ دخول الطالب — لا يُنشأ لقاصرٍ إلا بقرارٍ من المدرسة، والبوّابةُ مغلقةٌ حتى يُفعَّل portal_active';

-- v2.people
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 c88613a89077fb810b351a355864d313

CREATE TABLE v2.people (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    full_name text NOT NULL,
    national_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    contactable boolean DEFAULT true NOT NULL,
    status_changed_on date,
    tenant_id uuid NOT NULL,
    rank_key text,
    major_ar text,
    qualification_ar text,
    employee_no text,
    phone text,
    email text,
    is_seconded_partial boolean DEFAULT false NOT NULL,
    post_key text,
    CONSTRAINT people_pkey PRIMARY KEY (id),
    CONSTRAINT people_national_id_key UNIQUE (national_id),
    CONSTRAINT people_deceased_not_contactable_chk CHECK (((status <> 'deceased'::text) OR (contactable = false))),
    CONSTRAINT people_status_check CHECK ((status = ANY (ARRAY['active'::text, 'left'::text, 'deceased'::text])))
);
ALTER TABLE v2.people ENABLE ROW LEVEL SECURITY;
COMMENT ON COLUMN v2.people.major_ar IS 'التخصص الذي عُيّن به — غير المادة التي يُدرّسها فعلاً. وقد يُدرّس غير تخصصه، ويظهر ذلك في فحص الإسناد لا يُخفى.';
COMMENT ON COLUMN v2.people.is_seconded_partial IS 'منتدب انتداباً جزئياً — مستثنى من المناوبة والإشراف بنصّ ض01 في س-15-ا1.';
COMMENT ON COLUMN v2.people.post_key IS 'الوظيفة في الملاك — ثابتة ولا تتغير بالتكليف. والمعلّم يبقى معلّماً وإن كُلّف بالوكالة.';

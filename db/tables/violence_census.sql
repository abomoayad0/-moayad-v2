-- v2.violence_census
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 a701fe7c1789f12ea5e9e40493d072fd

CREATE TABLE v2.violence_census (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid NOT NULL,
    family text NOT NULL,
    level text DEFAULT 'school'::text NOT NULL,
    type_key text,
    metric_ar text NOT NULL,
    stage text,
    count_n integer DEFAULT 0 NOT NULL,
    plans_ar text,
    difficulties_ar text,
    future_actions_ar text,
    signed_counselor boolean DEFAULT false NOT NULL,
    signed_principal boolean DEFAULT false NOT NULL,
    sent_to_office_on date,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT violence_census_pkey PRIMARY KEY (id),
    CONSTRAINT violence_census_family_check CHECK ((family = ANY (ARRAY['عنف'::text, 'تنمر'::text]))),
    CONSTRAINT violence_census_level_check CHECK ((level = ANY (ARRAY['school'::text, 'office'::text, 'department'::text]))),
    CONSTRAINT violence_census_stage_check CHECK ((stage = ANY (ARRAY['primary'::text, 'intermediate'::text, 'secondary'::text])))
);
ALTER TABLE v2.violence_census ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.violence_census IS 'حصر حالات العنف (نموذج 1 ص44) والتنمر (نموذج 2 ص45). ويُعبّأ في المدرسة بتوقيع الموجه والمدير، ثم يُرسل لمكتب التعليم ويُستكمل بالنموذج نفسه، ثم لإدارة التوجيه بإدارة التعليم ويُستكمل، ثم تُرسل البيانات ضمن التقرير الختامي لبرامج التوجيه الطلابي. فالورقة الواحدة تصعد ثلاث درجات.';

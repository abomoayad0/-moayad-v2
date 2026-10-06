-- v2.branding
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 d6dc670c05d291d635d6f7301e8cf07f

CREATE TABLE v2.branding (
    school_id uuid NOT NULL,
    logo_path text,
    logo_position text DEFAULT 'right'::text,
    show_ministry_logo boolean DEFAULT true NOT NULL,
    primary_color text DEFAULT '#07a869'::text,
    accent_color text DEFAULT '#15445a'::text,
    header_ar text,
    footer_ar text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT branding_pkey PRIMARY KEY (school_id),
    CONSTRAINT branding_logo_position_check CHECK ((logo_position = ANY (ARRAY['right'::text, 'left'::text, 'center'::text])))
);
ALTER TABLE v2.branding ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.branding IS 'الهوية البصرية تُقرأ من القاعدة لا تُكتب في الكود — أساسها هوية الوزارة، ومن له شعار خاصّ يضيفه من لوحة التحكّم.';

-- v2.day_settings
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 e6e1ce3e032ec667cc6097b46fb7c810

CREATE TABLE v2.day_settings (
    school_id uuid NOT NULL,
    assembly_at time without time zone DEFAULT '06:45:00'::time without time zone NOT NULL,
    period1_at time without time zone DEFAULT '07:00:00'::time without time zone NOT NULL,
    period_minutes smallint DEFAULT 45 NOT NULL,
    prenotice_after_min smallint DEFAULT 10 NOT NULL,
    prenotice_on boolean DEFAULT true NOT NULL,
    close_at time without time zone DEFAULT '08:10:00'::time without time zone NOT NULL,
    close_note text DEFAULT 'منتصف الحصة الثانية — قرار مفرح'::text,
    late_grace_min smallint DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT day_settings_pkey PRIMARY KEY (school_id),
    CONSTRAINT day_settings_period_minutes_check CHECK (((period_minutes >= 20) AND (period_minutes <= 90)))
);
ALTER TABLE v2.day_settings ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.day_settings IS 'إعدادات اليوم الدراسي — كلها من البناء لا من الدليل، وتُضبط من لوحة التحكم ولا تُزرع في الكود.';

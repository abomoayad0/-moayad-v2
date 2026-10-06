-- v2.dismissal_settings
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 102f39771f05856493ac40a26a71d88c

CREATE TABLE v2.dismissal_settings (
    school_id uuid NOT NULL,
    dismiss_at time without time zone DEFAULT '12:30:00'::time without time zone NOT NULL,
    census_after_min smallint DEFAULT 15 NOT NULL,
    action_after_min smallint DEFAULT 30 NOT NULL,
    note text DEFAULT 'العتبتان منصوصتان: ض03 حصر المتأخرين بعد نهاية الدوام بـ15 دقيقة من قبل المناوب · ض06 عند التأخر بعد نهاية الدوام بـ30 دقيقة يُتخذ الإجراء المناسب'::text,
    CONSTRAINT dismissal_settings_pkey PRIMARY KEY (school_id)
);
ALTER TABLE v2.dismissal_settings ENABLE ROW LEVEL SECURITY;

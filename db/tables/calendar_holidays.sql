-- v2.calendar_holidays
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 3562c3cc98a1e7ca8cbcc94f18d758da

CREATE TABLE v2.calendar_holidays (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    year_id uuid NOT NULL,
    title_ar text NOT NULL,
    holiday_kind text NOT NULL,
    from_h text NOT NULL,
    from_g date NOT NULL,
    to_h text NOT NULL,
    to_g date NOT NULL,
    stops_work boolean DEFAULT true NOT NULL,
    announced_by text,
    source_ref text,
    note text,
    CONSTRAINT calendar_holidays_pkey PRIMARY KEY (id),
    CONSTRAINT calendar_holidays_holiday_kind_check CHECK ((holiday_kind = ANY (ARRAY['ministry_unified'::text, 'region_chosen'::text, 'region_suspension'::text, 'national_mourning'::text, 'royal_decree'::text]))),
    CONSTRAINT hol_dates CHECK ((to_g >= from_g))
);
ALTER TABLE v2.calendar_holidays ENABLE ROW LEVEL SECURITY;
COMMENT ON COLUMN v2.calendar_holidays.holiday_kind IS 'ministry_unified = موحّدة من الوزارة · region_chosen = مختارة من إدارة التعليم · region_suspension = تعليق دراسة لمنطقة · national_mourning = توقّف أو حداد عام · royal_decree = أمر ملكي.';
COMMENT ON COLUMN v2.calendar_holidays.stops_work IS 'تعليق الدراسة لا يوقف العمل: الطلاب لا دراسة لهم والمنسوبون على رأس العمل. فيُضبط false في هذه الحالة وحدها.';

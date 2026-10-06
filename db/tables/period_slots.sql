-- v2.period_slots
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 724d8a6a5b518d5b2650c4d94806a048

CREATE TABLE v2.period_slots (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    period_no smallint NOT NULL,
    starts_at time without time zone NOT NULL,
    ends_at time without time zone NOT NULL,
    label_ar text,
    CONSTRAINT period_slots_pkey PRIMARY KEY (id),
    CONSTRAINT period_slots_school_id_period_no_key UNIQUE (school_id, period_no),
    CONSTRAINT period_slots_period_no_check CHECK (((period_no >= 1) AND (period_no <= 9))),
    CONSTRAINT ps_time CHECK ((ends_at > starts_at))
);
ALTER TABLE v2.period_slots ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.period_slots IS 'حصص اليوم وتوقيتها. والخطط الدراسية (PLAN-5-OFF ص14 بند 4): «تُصمم المدرسة الجدول بعدد حصص يتراوح بين 6-7 حصص»، واليوم لا يتجاوز 7 ساعات.';

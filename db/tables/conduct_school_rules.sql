-- v2.conduct_school_rules
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 e758c1d7caccecef7488a99d7e6a70c2

CREATE TABLE v2.conduct_school_rules (
    school_id uuid NOT NULL,
    teaching_mode text DEFAULT 'onsite'::text NOT NULL,
    summon_after_workdays smallint DEFAULT 3 NOT NULL,
    summon_time time without time zone,
    set_by uuid,
    set_at timestamp with time zone DEFAULT now() NOT NULL,
    absence_truth text DEFAULT 'system'::text NOT NULL,
    CONSTRAINT conduct_school_rules_pkey PRIMARY KEY (school_id),
    CONSTRAINT conduct_school_rules_absence_truth_check CHECK ((absence_truth = ANY (ARRAY['system'::text, 'noor'::text]))),
    CONSTRAINT conduct_school_rules_summon_after_workdays_check CHECK (((summon_after_workdays >= 1) AND (summon_after_workdays <= 10))),
    CONSTRAINT conduct_school_rules_teaching_mode_check CHECK ((teaching_mode = ANY (ARRAY['onsite'::text, 'online'::text])))
);
ALTER TABLE v2.conduct_school_rules ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.conduct_school_rules IS 'إعداداتُ المدرسة في تطبيق قواعد السلوك — ليست من الدليل، ولكلّ مدرسة أن تضبطها';
COMMENT ON COLUMN v2.conduct_school_rules.teaching_mode IS 'نمطُ التعليم: حضوريّ أو عن بُعد — ويحدّد أيَّ سلّمٍ تعمل به المدرسة';
COMMENT ON COLUMN v2.conduct_school_rules.summon_after_workdays IS 'موعدُ دعوة وليّ الأمر بعد كم يومِ عملٍ — قرارُ مفرح: ثالثُ أيّام العمل';
COMMENT ON COLUMN v2.conduct_school_rules.summon_time IS 'ساعةُ المقابلة — ولا يُعتمد خطابُ الدعوة قبل ضبطها';
COMMENT ON COLUMN v2.conduct_school_rules.absence_truth IS 'مصدرُ الحقيقة في الغياب: system = سجلُّنا هو الأصل · noor = نورٌ هو الأصل · وقرارُ مفرح: system';

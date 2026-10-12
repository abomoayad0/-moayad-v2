-- v2.staff_lateness
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 6568c5ba5cbe76957ef5432c0c1aad14

CREATE TABLE v2.staff_lateness (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    person_id uuid NOT NULL,
    on_date date NOT NULL,
    duty_at time without time zone NOT NULL,
    arrived_at time without time zone NOT NULL,
    minutes_late smallint NOT NULL,
    fiscal_year smallint NOT NULL,
    excuse_state text DEFAULT 'none'::text NOT NULL,
    excuse_ar text,
    decided_by uuid,
    decided_at timestamp with time zone,
    decision_note text,
    note_ar text,
    recorded_by uuid,
    recorded_role text,
    recorded_at timestamp with time zone DEFAULT now() NOT NULL,
    voided_at timestamp with time zone,
    voided_by uuid,
    void_why text,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT staff_lateness_pkey PRIMARY KEY (id),
    CONSTRAINT staff_lateness_excuse_state_check CHECK ((excuse_state = ANY (ARRAY['none'::text, 'claimed'::text, 'accepted'::text, 'rejected'::text]))),
    CONSTRAINT staff_lateness_minutes_late_check CHECK ((minutes_late >= 0))
);
CREATE INDEX ix_staff_lateness_fy ON v2.staff_lateness USING btree (school_id, fiscal_year) WHERE (voided_at IS NULL);
CREATE UNIQUE INDEX ux_staff_lateness_live ON v2.staff_lateness USING btree (school_id, person_id, on_date) WHERE (voided_at IS NULL);
ALTER TABLE v2.staff_lateness ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.staff_lateness IS 'تأخّرُ المنسوب عن الدوام الرسميّ بالدقائق — سندُه س-١٦-ا-١ سياسة ٠٣ ص٣٢٦. ويُقاس على بداية الدوام الرسميّ، وهي عندنا day_settings.period1_at لأنّ سياسة ٠١ ص٣٢٦ تنصّ أنّ الاصطفافَ يبدأ قبل ربع ساعةٍ من الوقت المقرّر للدوام — وهذا تفسيرُنا للنصّ لا نصُّه. وfiscal_year ميلاديٌّ لأنّ النصَّ يقول «خلال العام الماليّ» والعامُ الماليُّ السعوديُّ ميلاديٌّ.';

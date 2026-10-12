-- v2.reading_sessions
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 578c67505a16223cd66b4e5cd58cd555

CREATE TABLE v2.reading_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid,
    term_no smallint,
    on_date date NOT NULL,
    weekday smallint NOT NULL,
    period_no smallint NOT NULL,
    section_id uuid,
    person_id uuid NOT NULL,
    minutes smallint NOT NULL,
    done boolean DEFAULT true NOT NULL,
    skipped_why_ar text,
    recorded_by uuid,
    recorded_role text,
    recorded_at timestamp with time zone DEFAULT now() NOT NULL,
    voided_at timestamp with time zone,
    voided_by uuid,
    void_why text,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT reading_sessions_pkey PRIMARY KEY (id),
    CONSTRAINT reading_sessions_skip_ck CHECK ((done OR (skipped_why_ar IS NOT NULL)))
);
CREATE INDEX ix_reading_sessions_day ON v2.reading_sessions USING btree (school_id, on_date) WHERE (voided_at IS NULL);
CREATE UNIQUE INDEX ux_reading_sessions_live ON v2.reading_sessions USING btree (school_id, person_id, on_date, period_no) WHERE (voided_at IS NULL);
ALTER TABLE v2.reading_sessions ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.reading_sessions IS 'استقطاعُ عشرِ دقائقَ من الحصّة لمتابعة القراءة والكتابة — س-٨-ا-٣ سياسة ٠٤ ص٢٠٩. والنطاقُ الصفوفُ ٢–٦ ومعدَّلُه أربعُ حصصٍ يوميًّا، وكلاهما منصوصٌ في مرجع الأرقام. وما لم يُنفَّذ يُسجَّل بسببٍ مكتوبٍ لا يُحذف.';

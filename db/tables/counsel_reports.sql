-- v2.counsel_reports
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 6a597d0e0e9cc79d7ba2ef8782af3cdf

CREATE TABLE v2.counsel_reports (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    case_id uuid NOT NULL,
    issued_on date DEFAULT CURRENT_DATE NOT NULL,
    issued_by uuid,
    sessions_n smallint,
    span_ar text,
    last_resp text,
    judgement text,
    opinion text NOT NULL,
    recommend text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT counsel_reports_pkey PRIMARY KEY (id)
);
ALTER TABLE v2.counsel_reports ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.counsel_reports IS 'تقريرُ دراسة الحالة — يخرج للّجنة؛ ملخّصٌ بلا نصّ الجلسات ولا الدراسة';

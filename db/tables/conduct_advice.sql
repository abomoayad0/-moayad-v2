-- v2.conduct_advice
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 66b28d3d6f042d72e4116d135b85c708

CREATE TABLE v2.conduct_advice (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid,
    problem_id integer,
    occurrence smallint NOT NULL,
    text_ar text NOT NULL,
    active boolean DEFAULT true NOT NULL,
    CONSTRAINT conduct_advice_pkey PRIMARY KEY (id),
    CONSTRAINT conduct_advice_school_id_problem_id_occurrence_key UNIQUE (school_id, problem_id, occurrence)
);
ALTER TABLE v2.conduct_advice ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.conduct_advice IS 'النصيحةُ التربويّةُ تُعطى للطالب عند الرصد وتظهر لوليّه — فالرصدُ تنبيهٌ لا عقوبة. ثلاثٌ لكلّ سلوكٍ تتدرّج بالرصدة. من المحاكي ٦/١٠/٢٠٢٦';

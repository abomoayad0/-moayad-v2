-- v2.curriculum_units
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 1bc290809bc2d250447c603dba1aef8c

CREATE TABLE v2.curriculum_units (
    id uuid NOT NULL,
    stage text NOT NULL,
    grade smallint NOT NULL,
    subject_ar text NOT NULL,
    unit_no smallint,
    title_ar text NOT NULL,
    term_no smallint,
    ord smallint,
    is_branch boolean DEFAULT false NOT NULL,
    source_doc text,
    verified boolean DEFAULT false NOT NULL,
    imported_at timestamp with time zone DEFAULT now() NOT NULL,
    src_rn integer,
    CONSTRAINT curriculum_units_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX curr_units_src_rn_uq ON v2.curriculum_units USING btree (src_rn);
ALTER TABLE v2.curriculum_units ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.curriculum_units IS 'وحداتُ المنهج — مرجعٌ عامٌّ. نُقل من مؤيّد القديم ٩/١٠/٢٠٢٦ بمعرّفاته الأصليّة.';
COMMENT ON COLUMN v2.curriculum_units.src_rn IS 'ترتيبُ الوحدة في مؤيّد القديم (row_number over order by id) — جسرُ النقل، ويبقى شاهدًا على المصدر.';

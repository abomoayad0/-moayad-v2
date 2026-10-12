-- v2.curriculum_gaps
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 0d9fc6d33596a678522e1192c085e4a4

CREATE TABLE v2.curriculum_gaps (
    id uuid NOT NULL,
    stage text,
    grade smallint,
    subject_ar text,
    seeded_periods integer,
    official_periods integer,
    note_ar text,
    recorded_at timestamp with time zone,
    imported_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT curriculum_gaps_pkey PRIMARY KEY (id)
);
ALTER TABLE v2.curriculum_gaps ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.curriculum_gaps IS '🔑 شاهدُ النقص — الفرقُ بين الحصص المزروعة والرسميّة. نُقل لأنّ النقصَ يُسمّى ولا يُكتم.';

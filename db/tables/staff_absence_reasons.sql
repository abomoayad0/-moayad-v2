-- v2.staff_absence_reasons
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 ede85430b100c3574a8c33ad4e326894

CREATE TABLE v2.staff_absence_reasons (
    key text NOT NULL,
    label_ar text NOT NULL,
    ord smallint DEFAULT 50 NOT NULL,
    counts_absent boolean DEFAULT false NOT NULL,
    needs_note boolean DEFAULT false NOT NULL,
    active boolean DEFAULT true NOT NULL,
    source_ar text,
    CONSTRAINT staff_absence_reasons_pkey PRIMARY KEY (key)
);
ALTER TABLE v2.staff_absence_reasons ENABLE ROW LEVEL SECURITY;

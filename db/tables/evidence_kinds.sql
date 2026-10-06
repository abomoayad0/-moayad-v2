-- v2.evidence_kinds
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 7e3ff1f29bb9d72eac2ddb518958fe2e

CREATE TABLE v2.evidence_kinds (
    key text NOT NULL,
    label_ar text NOT NULL,
    hint_ar text,
    needs_date boolean DEFAULT false NOT NULL,
    needs_text boolean DEFAULT false NOT NULL,
    needs_file boolean DEFAULT false NOT NULL,
    needs_ref boolean DEFAULT false NOT NULL,
    needs_people boolean DEFAULT false NOT NULL,
    needs_signature boolean DEFAULT false NOT NULL,
    needs_form smallint,
    lbl_date text,
    lbl_text text,
    lbl_file text,
    lbl_ref text,
    lbl_people text,
    lbl_sign text,
    CONSTRAINT evidence_kinds_pkey PRIMARY KEY (key)
);
ALTER TABLE v2.evidence_kinds ENABLE ROW LEVEL SECURITY;

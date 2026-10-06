-- v2.proc_cards
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 bc1ab9701028299104dcc27a036b0db9

CREATE TABLE v2.proc_cards (
    code text NOT NULL,
    title text NOT NULL,
    guide_code text NOT NULL,
    page_from integer,
    page_to integer,
    group_no smallint,
    section_no smallint,
    version_no text,
    verified_by text,
    verified_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT proc_cards_pkey PRIMARY KEY (code),
    CONSTRAINT proc_cards_check CHECK (((page_to IS NULL) OR (page_from IS NULL) OR (page_to >= page_from)))
);
ALTER TABLE v2.proc_cards ENABLE ROW LEVEL SECURITY;

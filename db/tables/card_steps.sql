-- v2.card_steps
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 1965bfcd67f45701469f9aa3aa8709d3

CREATE TABLE v2.card_steps (
    card_code text NOT NULL,
    step_no smallint NOT NULL,
    body text NOT NULL,
    owner_role text,
    is_system boolean DEFAULT false NOT NULL,
    is_terminal boolean DEFAULT false NOT NULL,
    CONSTRAINT card_steps_pkey PRIMARY KEY (card_code, step_no),
    CONSTRAINT card_steps_body_check CHECK ((length(btrim(body)) > 0))
);
ALTER TABLE v2.card_steps ENABLE ROW LEVEL SECURITY;

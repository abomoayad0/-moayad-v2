-- v2.card_matrix
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 fa5543649efe36d1c173bce9fed3f1e8

CREATE TABLE v2.card_matrix (
    card_code text NOT NULL,
    step_no smallint NOT NULL,
    role text NOT NULL,
    raci text NOT NULL,
    CONSTRAINT card_matrix_pkey PRIMARY KEY (card_code, step_no, role, raci),
    CONSTRAINT card_matrix_raci_check CHECK ((raci = ANY (ARRAY['A'::text, 'R'::text, 'C'::text, 'I'::text])))
);
ALTER TABLE v2.card_matrix ENABLE ROW LEVEL SECURITY;

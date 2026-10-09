-- v2.ladder_table_scope
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 6e22362df03ca2175659bb36e614de83

CREATE TABLE v2.ladder_table_scope (
    tbl text NOT NULL,
    serves_kinds text[] DEFAULT '{}'::text[] NOT NULL,
    cross_ladder boolean NOT NULL,
    note_ar text NOT NULL,
    decided_on date DEFAULT CURRENT_DATE NOT NULL,
    CONSTRAINT ladder_table_scope_pkey PRIMARY KEY (tbl)
);
ALTER TABLE v2.ladder_table_scope ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.ladder_table_scope IS 'إعلانُ غرضِ كلّ جدولِ مجالٍ يُشير إلى بندِ سلّم — والمرآةُ تحكم به وتعرض الدليلَ المضادَّ له · وكلُّ جدولٍ جديدٍ من هذا الجنس يُعلَن هنا يومَ يُبنى، وإلّا صرخت المرآة';

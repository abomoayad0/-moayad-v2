-- v2.phrase_bank
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 504d33c4cc05c399e836200f3553f864

CREATE TABLE v2.phrase_bank (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid,
    bank_key text NOT NULL,
    problem_id integer,
    text_ar text NOT NULL,
    ord smallint DEFAULT 0 NOT NULL,
    active boolean DEFAULT true NOT NULL,
    CONSTRAINT phrase_bank_pkey PRIMARY KEY (id)
);
CREATE INDEX ix_pb ON v2.phrase_bank USING btree (bank_key, problem_id);
ALTER TABLE v2.phrase_bank ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.phrase_bank IS 'بنكُ العبارات التربويّة — لكلّ الفريق إلّا الطالبَ ووليَّ الأمر، فكلامُهما شهادةٌ لا تُملى عليهما. المفاتيح: cause · limit · taskWhat · callWhat · csSay · csSeen · csFactors · csPlan · referWhy · referAsk';

-- v2.inheritance_rules
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 b56adc5e35de8ce007c431a73308b869

CREATE TABLE v2.inheritance_rules (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    vacant_post_key text NOT NULL,
    heir_post_key text,
    heir_is_assigned_teacher boolean DEFAULT false NOT NULL,
    condition_note text,
    source_page text NOT NULL,
    CONSTRAINT inheritance_rules_pkey PRIMARY KEY (id),
    CONSTRAINT inheritance_rules_check CHECK (((heir_post_key IS NOT NULL) OR heir_is_assigned_teacher))
);
ALTER TABLE v2.inheritance_rules ENABLE ROW LEVEL SECURITY;

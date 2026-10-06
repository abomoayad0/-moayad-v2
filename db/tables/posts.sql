-- v2.posts
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 2050dc7f7d947c4785343959ea6b84f0

CREATE TABLE v2.posts (
    key text NOT NULL,
    label_ar text NOT NULL,
    kind text NOT NULL,
    source_page text NOT NULL,
    CONSTRAINT posts_pkey PRIMARY KEY (key),
    CONSTRAINT posts_kind_check CHECK ((kind = ANY (ARRAY['leadership'::text, 'deputy'::text, 'specialist'::text, 'teaching'::text, 'admin'::text, 'support'::text])))
);
ALTER TABLE v2.posts ENABLE ROW LEVEL SECURITY;

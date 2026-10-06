-- v2.structure_posts
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 229d7a235f5d692d477059d13052c6e4

CREATE TABLE v2.structure_posts (
    structure_code text NOT NULL,
    post_key text NOT NULL,
    parent_post_key text,
    CONSTRAINT structure_posts_pkey PRIMARY KEY (structure_code, post_key)
);
ALTER TABLE v2.structure_posts ENABLE ROW LEVEL SECURITY;

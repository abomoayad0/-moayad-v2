-- v2.day_segments
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 fa47fe655ac791681ed9df3c23f35ec2

CREATE TABLE v2.day_segments (
    key text NOT NULL,
    label_ar text NOT NULL,
    ord smallint NOT NULL,
    is_period boolean DEFAULT false NOT NULL,
    owner_role text NOT NULL,
    source_ar text NOT NULL,
    CONSTRAINT day_segments_pkey PRIMARY KEY (key)
);
ALTER TABLE v2.day_segments ENABLE ROW LEVEL SECURITY;

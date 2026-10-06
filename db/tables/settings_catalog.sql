-- v2.settings_catalog
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 e2657e36ffcf1ef81a399f05a6ee73c7

CREATE TABLE v2.settings_catalog (
    key text NOT NULL,
    label_ar text NOT NULL,
    group_ar text NOT NULL,
    table_name text NOT NULL,
    editable boolean DEFAULT true NOT NULL,
    locked_why text,
    source_ar text,
    note_ar text,
    bridge_ar text,
    allowed_cols text[],
    own_bridge boolean DEFAULT false NOT NULL,
    pk_col text,
    ctx_cols text[],
    cols_ar jsonb,
    CONSTRAINT settings_catalog_pkey PRIMARY KEY (key)
);
ALTER TABLE v2.settings_catalog ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.settings_catalog IS 'فهرس لوحة التحكّم: ما تعدّله المدرسة وما لا يُمسّ. الثابت الوزاري مقفل بنصّ سنده، والفضاء المدرسي حرّ.';
COMMENT ON COLUMN v2.settings_catalog.allowed_cols IS 'الأعمدةُ التي يقبلها التعديلُ العامّ — وما سواها يُرفض. وفارغةٌ = لا تعديلَ عامًّا البتّة';
COMMENT ON COLUMN v2.settings_catalog.own_bridge IS 'بابٌ له جسرُه الخاصُّ بحرّاسه — ولا يُمسّ من التعديل العامّ';

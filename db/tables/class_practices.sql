-- v2.class_practices
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 3473f7a55a503c278081c4c99350fac0

CREATE TABLE v2.class_practices (
    code text NOT NULL,
    polarity text NOT NULL,
    kind text DEFAULT 'practice'::text NOT NULL,
    title_ar text NOT NULL,
    points numeric(4,2) DEFAULT 0 NOT NULL,
    scope text NOT NULL,
    zone text,
    threshold_count smallint,
    threshold_days smallint,
    escalate_to integer,
    escalate_note text,
    once_per_day boolean DEFAULT false NOT NULL,
    ord smallint DEFAULT 0 NOT NULL,
    active boolean DEFAULT true NOT NULL,
    origin text DEFAULT 'المدرسة'::text NOT NULL,
    school_id uuid,
    based_on text,
    note_ar text,
    CONSTRAINT class_practices_pkey PRIMARY KEY (code),
    CONSTRAINT class_practices_kind_check CHECK ((kind = ANY (ARRAY['practice'::text, 'state'::text]))),
    CONSTRAINT class_practices_polarity_check CHECK ((polarity = ANY (ARRAY['positive'::text, 'negative'::text])))
);
CREATE INDEX ix_cp_school ON v2.class_practices USING btree (school_id, scope, active);
ALTER TABLE v2.class_practices ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.class_practices IS 'ممارسات الصف — طبقة دون اللائحة الوزارية. لا تمسّ درجة السلوك، وتُعالج بين المعلم وطالبه. فإذا بلغت حدّها (threshold_count خلال threshold_days) صُعّدت إلى مشكلة سلوكية في اللائحة (escalate_to). منقولة تصميمًا من النظام القائم، وسندها نموذج (10) في توزيع الدرجات: «السلوك المتميز 20٪ — ممارسات متسقة مع القيم».';
COMMENT ON COLUMN v2.class_practices.once_per_day IS 'لا تُرصد أكثر من مرة في اليوم مهما تعددت الحصص.';
COMMENT ON COLUMN v2.class_practices.origin IS 'المدرسة: اجتهاد مدرسي لا نصّ وزاري. ويُعدَّل من لوحة التحكم.';
COMMENT ON COLUMN v2.class_practices.school_id IS 'فارغٌ = مشتركةٌ للمجمّع · ومملوءٌ = خاصّةٌ بهذي المدرسة. قرار مفرح ٦/١٠/٢٠٢٦';
COMMENT ON COLUMN v2.class_practices.based_on IS 'المشتركةُ التي فُصلت عنها — فالمفصولةُ تحجب أصلَها في مدرستها';

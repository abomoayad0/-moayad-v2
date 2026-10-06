-- v2.class_practices
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 4ef24a453f38b4dfef0420506bc17be7

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
    CONSTRAINT class_practices_pkey PRIMARY KEY (code),
    CONSTRAINT class_practices_kind_check CHECK ((kind = ANY (ARRAY['practice'::text, 'state'::text]))),
    CONSTRAINT class_practices_polarity_check CHECK ((polarity = ANY (ARRAY['positive'::text, 'negative'::text])))
);
ALTER TABLE v2.class_practices ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.class_practices IS 'ممارسات الصف — طبقة دون اللائحة الوزارية. لا تمسّ درجة السلوك، وتُعالج بين المعلم وطالبه. فإذا بلغت حدّها (threshold_count خلال threshold_days) صُعّدت إلى مشكلة سلوكية في اللائحة (escalate_to). منقولة تصميمًا من النظام القائم، وسندها نموذج (10) في توزيع الدرجات: «السلوك المتميز 20٪ — ممارسات متسقة مع القيم».';
COMMENT ON COLUMN v2.class_practices.once_per_day IS 'لا تُرصد أكثر من مرة في اليوم مهما تعددت الحصص.';
COMMENT ON COLUMN v2.class_practices.origin IS 'المدرسة: اجتهاد مدرسي لا نصّ وزاري. ويُعدَّل من لوحة التحكم.';

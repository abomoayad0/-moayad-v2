-- v2.mail_items
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 ada7f5953671709ce20b6b2da0f9a53c

CREATE TABLE v2.mail_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    mail_id uuid NOT NULL,
    ord smallint NOT NULL,
    text_ar text NOT NULL,
    kind text NOT NULL,
    starts_on date,
    ends_on date,
    dates_source text,
    proposed_by text DEFAULT 'يدوي'::text NOT NULL,
    approved boolean DEFAULT false NOT NULL,
    approved_by uuid,
    approved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT mail_items_pkey PRIMARY KEY (id),
    CONSTRAINT mail_items_mail_id_ord_key UNIQUE (mail_id, ord),
    CONSTRAINT item_dates CHECK (((ends_on IS NULL) OR (starts_on IS NULL) OR (ends_on >= starts_on))),
    CONSTRAINT mail_items_dates_source_check CHECK ((dates_source = ANY (ARRAY['من نص الخطاب'::text, 'من البناء'::text, 'من المدير'::text]))),
    CONSTRAINT mail_items_kind_check CHECK ((kind = ANY (ARRAY['تكليف'::text, 'إبلاغ بالعلم'::text]))),
    CONSTRAINT mail_items_proposed_by_check CHECK ((proposed_by = ANY (ARRAY['يدوي'::text, 'آلي'::text]))),
    CONSTRAINT mail_items_text_ar_check CHECK ((btrim(text_ar) <> ''::text))
);
ALTER TABLE v2.mail_items ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.mail_items IS 'بنود متطلبات التنفيذ. الخطوة 04 في س-15-ا3: «حفظ بنود متطلبات التنفيذ للمتابعة». 🔸 والتفكيك الآلي اقتراح يُعرض على ماسك البريد؛ لا يُكلَّف أحد ببند لم يُقَرّ (approved).';

-- v2.official_forms
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 a006f6cf22bf44941a805236929ad25d

CREATE TABLE v2.official_forms (
    form_no smallint NOT NULL,
    title_ar text NOT NULL,
    is_secret boolean DEFAULT false NOT NULL,
    secrecy_ar text,
    scope_ar text NOT NULL,
    owner_role text,
    signers text[],
    columns_ar text[],
    fields_ar text[],
    rows_fixed text[],
    source_doc text NOT NULL,
    source_page text NOT NULL,
    built boolean DEFAULT false NOT NULL,
    build_note text,
    source_guide text DEFAULT 'CONDUCT-1447-OFF'::text NOT NULL,
    goes_to text[],
    goes_to_ar text[],
    final_label_ar text,
    final_done_ar text,
    CONSTRAINT official_forms_pkey PRIMARY KEY (form_no)
);
ALTER TABLE v2.official_forms ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.official_forms IS 'النماذج الرسمية السبعة عشر الملحقة بقواعد السلوك والمواظبة (CONDUCT-1447-OFF ص56). كل نموذج بأعمدته وحقوله وموقّعيه كما طُبع — يُملأ من بيانات النظام ويُطبع، ولا يُؤلَّف نصّه.';
COMMENT ON COLUMN v2.official_forms.source_guide IS 'الدليل الذي ورد فيه النموذج. نماذج قواعد السلوك أرقامها 1–17، ونماذج رفق 101–104.';
COMMENT ON COLUMN v2.official_forms.goes_to IS 'إلى من يصل النموذج بعد اعتماده: guardian بوابة ولي الأمر · student الطالب · counselor الموجه · committee لجنة التوجيه · external جهة خارجية · school يبقى في المدرسة.';
COMMENT ON COLUMN v2.official_forms.final_label_ar IS 'نصّ زرّ الإنهاء: «أرسله إلى …» لما يخرج من المدرسة، و«اعتمده» لما يبقى فيها.';

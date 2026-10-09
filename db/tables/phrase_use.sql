-- v2.phrase_use
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 077dd63a4e80f827fa3af89140d13015

CREATE TABLE v2.phrase_use (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    phrase_id uuid NOT NULL,
    school_id uuid,
    person_id uuid,
    form_no smallint,
    field_key text,
    used_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT phrase_use_pkey PRIMARY KEY (id)
);
CREATE INDEX phrase_use_phrase_idx ON v2.phrase_use USING btree (phrase_id, school_id);
ALTER TABLE v2.phrase_use ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.phrase_use IS 'كلُّ عبارةٍ تُختار تُعدّ — فترتفع في العرض · والمكتبةُ تنمو من الممارسة لا من التخمين';

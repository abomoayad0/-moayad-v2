-- v2.merit_opportunities
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 32cc495e1fbe711d770db7b02d4336b4

CREATE TABLE v2.merit_opportunities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    merit_id integer NOT NULL,
    year_id uuid,
    term_no smallint,
    kind text DEFAULT 'منظَّمة'::text NOT NULL,
    title_ar text,
    when_ar text NOT NULL,
    capacity smallint,
    held_by uuid,
    opened_by uuid,
    opened_at timestamp with time zone DEFAULT now() NOT NULL,
    state text DEFAULT 'مفتوحة'::text NOT NULL,
    close_why text,
    closed_at timestamp with time zone,
    plan_note text,
    planned_at timestamp with time zone,
    planned_by uuid,
    is_test boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT merit_opportunities_pkey PRIMARY KEY (id),
    CONSTRAINT merit_opportunities_kind_check CHECK ((kind = ANY (ARRAY['منظَّمة'::text, 'فرديّة'::text, 'آليّة'::text]))),
    CONSTRAINT merit_opportunities_state_check CHECK ((state = ANY (ARRAY['مفتوحة'::text, 'مُغلقة'::text, 'مُقدَّرة'::text, 'ملغاة'::text])))
);
CREATE INDEX ix_mo_school ON v2.merit_opportunities USING btree (school_id, state);
ALTER TABLE v2.merit_opportunities ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.merit_opportunities IS 'فرصُ تعويض درجات السلوك — تفتحها لجنةُ التوجيه (ص١٢ بند ١٠) بالتنسيق مع رائد النشاط (بند ٦)';

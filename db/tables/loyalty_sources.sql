-- v2.loyalty_sources
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 3ebdf7965c80e82e010058312541fbc6

CREATE TABLE v2.loyalty_sources (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid,
    code text NOT NULL,
    title_ar text NOT NULL,
    kind text DEFAULT 'earn'::text NOT NULL,
    points smallint NOT NULL,
    who_may text[] DEFAULT '{}'::text[] NOT NULL,
    week_cap smallint,
    needs_note boolean DEFAULT false NOT NULL,
    active boolean DEFAULT true NOT NULL,
    ord smallint DEFAULT 0 NOT NULL,
    note_ar text,
    set_by uuid,
    set_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT loyalty_sources_pkey PRIMARY KEY (id),
    CONSTRAINT loyalty_sources_school_id_code_key UNIQUE (school_id, code),
    CONSTRAINT loyalty_sources_kind_check CHECK ((kind = ANY (ARRAY['earn'::text, 'deduct'::text]))),
    CONSTRAINT loyalty_sources_points_check CHECK ((points > 0))
);
ALTER TABLE v2.loyalty_sources ENABLE ROW LEVEL SECURITY;

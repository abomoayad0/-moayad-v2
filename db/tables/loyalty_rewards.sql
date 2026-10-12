-- v2.loyalty_rewards
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 cd6ce9beed7b6d343bf2bc38fe61474a

CREATE TABLE v2.loyalty_rewards (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid,
    code text NOT NULL,
    title_ar text NOT NULL,
    price smallint NOT NULL,
    who_may_spend text[] DEFAULT '{}'::text[] NOT NULL,
    needs_principal boolean DEFAULT false NOT NULL,
    stock smallint,
    active boolean DEFAULT true NOT NULL,
    ord smallint DEFAULT 0 NOT NULL,
    note_ar text,
    set_by uuid,
    set_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT loyalty_rewards_pkey PRIMARY KEY (id),
    CONSTRAINT loyalty_rewards_school_id_code_key UNIQUE (school_id, code),
    CONSTRAINT loyalty_rewards_price_check CHECK ((price > 0))
);
ALTER TABLE v2.loyalty_rewards ENABLE ROW LEVEL SECURITY;

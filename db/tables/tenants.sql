-- v2.tenants
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 6c3c9b115b2c5aef65962a07e9e34946

CREATE TABLE v2.tenants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name_ar text NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT tenants_pkey PRIMARY KEY (id),
    CONSTRAINT tenants_status_check CHECK ((status = ANY (ARRAY['active'::text, 'suspended'::text, 'closed'::text])))
);
ALTER TABLE v2.tenants ENABLE ROW LEVEL SECURITY;

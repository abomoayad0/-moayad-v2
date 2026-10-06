-- v2.mail_targets
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 8f9848cddeb5d8d3c73099b7657c8e5b

CREATE TABLE v2.mail_targets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    item_id uuid NOT NULL,
    target_kind text NOT NULL,
    person_id uuid,
    role_ar text,
    assignment_ar text,
    scope_note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    pending_expansion boolean DEFAULT false NOT NULL,
    pending_note text,
    CONSTRAINT mail_targets_pkey PRIMARY KEY (id),
    CONSTRAINT mail_targets_target_kind_check CHECK ((target_kind = ANY (ARRAY['person'::text, 'persons'::text, 'role'::text, 'assignment'::text, 'all_staff'::text, 'students'::text, 'guardians'::text]))),
    CONSTRAINT tgt_assign CHECK (((target_kind <> 'assignment'::text) OR (btrim(COALESCE(assignment_ar, ''::text)) <> ''::text))),
    CONSTRAINT tgt_person CHECK (((target_kind <> ALL (ARRAY['person'::text, 'persons'::text])) OR (person_id IS NOT NULL))),
    CONSTRAINT tgt_role CHECK (((target_kind <> 'role'::text) OR (btrim(COALESCE(role_ar, ''::text)) <> ''::text)))
);
ALTER TABLE v2.mail_targets ENABLE ROW LEVEL SECURITY;
COMMENT ON COLUMN v2.mail_targets.target_kind IS 'person شخص بعينه · persons أشخاص معيّنون · role شخص بمنصبه (ينتقل التكليف مع شاغل المنصب) · assignment شخص بتكليفه · all_staff عموم المنسوبين · students الطلاب · guardians أولياء الأمور.';
COMMENT ON COLUMN v2.mail_targets.pending_expansion IS 'التوجيه بالمنصب أو التكليف لا يُفرَد إلى أشخاص حتى يُسجَّل المنسوبون ومناصبهم. فيبقى موسوماً معلّقاً، وتُفتح إقراراته متى سُجّلوا.';

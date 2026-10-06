-- v2.mail_followups
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 b18c15f52afbf9bb335c18e5d24a41e0

CREATE TABLE v2.mail_followups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    item_id uuid NOT NULL,
    person_id uuid,
    role_ar text,
    status text DEFAULT 'open'::text NOT NULL,
    due_on date,
    reminded_at timestamp with time zone,
    reminders_n smallint DEFAULT 0 NOT NULL,
    done_at timestamp with time zone,
    done_by uuid,
    evidence_ref text,
    close_note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT mail_followups_pkey PRIMARY KEY (id),
    CONSTRAINT fu_close_note CHECK (((status <> 'closed'::text) OR (btrim(COALESCE(close_note, ''::text)) <> ''::text))),
    CONSTRAINT mail_followups_status_check CHECK ((status = ANY (ARRAY['open'::text, 'in_progress'::text, 'done'::text, 'closed'::text, 'not_required'::text])))
);
CREATE INDEX mf_item_idx ON v2.mail_followups USING btree (item_id);
ALTER TABLE v2.mail_followups ENABLE ROW LEVEL SECURITY;

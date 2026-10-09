-- v2.absence_tasks
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 b0a6e53557cbf842c09b1304c96c9017

CREATE TABLE v2.absence_tasks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    case_id uuid NOT NULL,
    item_id integer,
    ord smallint NOT NULL,
    kind text NOT NULL,
    text_ar text NOT NULL,
    owner_role text NOT NULL,
    origin text NOT NULL,
    status text DEFAULT 'open'::text NOT NULL,
    skip_reason text,
    done_by uuid,
    done_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    evidence_kind text,
    ev_on date,
    ev_text text,
    ev_file text,
    ev_ref text,
    ev_people text,
    ev_signed boolean,
    ev_refused_reason text,
    owner_person uuid,
    delegated_by uuid,
    delegated_at timestamp with time zone,
    delegate_note text,
    is_standing boolean DEFAULT false NOT NULL,
    CONSTRAINT absence_tasks_pkey PRIMARY KEY (id),
    CONSTRAINT absence_tasks_status_check CHECK ((status = ANY (ARRAY['open'::text, 'done'::text, 'skipped'::text, 'refused'::text]))),
    CONSTRAINT att_task_skip_reason CHECK (((status <> 'skipped'::text) OR (btrim(COALESCE(skip_reason, ''::text)) <> ''::text)))
);
CREATE INDEX atsk_case_idx ON v2.absence_tasks USING btree (case_id);
ALTER TABLE v2.absence_tasks ENABLE ROW LEVEL SECURITY;
COMMENT ON COLUMN v2.absence_tasks.is_standing IS 'حالٌ مستمرّةٌ لا فعلٌ يُؤشَّر — تُعرض ولا تُطالَب · وتبقى status=open فلا تُدَّعى مُقفلة';

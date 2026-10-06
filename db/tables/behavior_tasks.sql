-- v2.behavior_tasks
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 71bcbae74ed137b486af9baa1becf99c

CREATE TABLE v2.behavior_tasks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    record_id uuid NOT NULL,
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
    due_on date,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    response_level text,
    response_note text,
    response_by uuid,
    response_at timestamp with time zone,
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
    CONSTRAINT behavior_tasks_pkey PRIMARY KEY (id),
    CONSTRAINT behavior_tasks_response_level_check CHECK ((response_level = ANY (ARRAY['استجاب'::text, 'استجاب جزئياً'::text, 'لم يستجب'::text, 'لم يُقيَّم بعد'::text]))),
    CONSTRAINT behavior_tasks_status_check CHECK ((status = ANY (ARRAY['open'::text, 'done'::text, 'skipped'::text, 'refused'::text, 'auto'::text]))),
    CONSTRAINT task_skip_needs_reason CHECK (((status <> 'skipped'::text) OR (btrim(COALESCE(skip_reason, ''::text)) <> ''::text)))
);
CREATE INDEX bt_open_idx ON v2.behavior_tasks USING btree (owner_role, status);
CREATE INDEX bt_record_idx ON v2.behavior_tasks USING btree (record_id);
ALTER TABLE v2.behavior_tasks ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.behavior_tasks IS 'المهام المولَّدة آلياً من بنود الإجراء عند الرصد. لا تُحذف؛ تُغلق أو تُتجاوز بسبب مكتوب.';
COMMENT ON COLUMN v2.behavior_tasks.response_level IS 'مدى الاستجابة — عمود منصوص في نموذج رصد المعلم لمشكلة سلوكية CONDUCT-1447-OFF ص61. وهو حكم المعلم على أثر الإجراء ولا يُستنتج آلياً.';
COMMENT ON COLUMN v2.behavior_tasks.owner_person IS 'من كُلّف بالمهمة بعينه. فارغ = المسؤول بصفته. والوكيل يحوّلها لمن يراه بسبب مكتوب، ويبقى الأصل محفوظًا.';

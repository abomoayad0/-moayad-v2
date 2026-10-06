-- v2.committee_meetings
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 7ebbcb1fa76013b64fb7ce09aa4c480f

CREATE TABLE v2.committee_meetings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    committee_key text NOT NULL,
    year_id uuid,
    term_no smallint,
    kind text DEFAULT 'شهري'::text NOT NULL,
    meeting_no smallint,
    held_on date,
    started_at time without time zone,
    ended_at time without time zone,
    place_ar text,
    called_by uuid,
    called_at timestamp with time zone,
    agenda_ar text,
    status text DEFAULT 'مدعوّ إليه'::text NOT NULL,
    quorum_met boolean,
    minutes_by uuid,
    minutes_at timestamp with time zone,
    approved_by uuid,
    approved_at timestamp with time zone,
    cancel_reason text,
    is_test boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT committee_meetings_pkey PRIMARY KEY (id),
    CONSTRAINT committee_meetings_kind_check CHECK ((kind = ANY (ARRAY['شهري'::text, 'طارئ'::text]))),
    CONSTRAINT committee_meetings_status_check CHECK ((status = ANY (ARRAY['مدعوّ إليه'::text, 'منعقد'::text, 'موثّق'::text, 'معتمد'::text, 'ملغًى'::text])))
);
CREATE INDEX ix_cm_school ON v2.committee_meetings USING btree (school_id, committee_key, held_on);
ALTER TABLE v2.committee_meetings ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.committee_meetings IS 'اجتماعُ لجنةٍ — ص١٧ وص١٩: تُعقد بدعوةٍ من رئيسها شهريًّا، وله الدعوةُ لاجتماعٍ طارئ';

-- v2.lesson_item_progress
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 0e7589f504fa9e0aef6435e7741c6b4a

CREATE TABLE v2.lesson_item_progress (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    item_id uuid NOT NULL,
    section_id uuid NOT NULL,
    state text NOT NULL,
    periods_used smallint,
    on_date date DEFAULT CURRENT_DATE NOT NULL,
    why_ar text,
    by_person uuid,
    at timestamp with time zone DEFAULT now() NOT NULL,
    voided_at timestamp with time zone,
    voided_by uuid,
    void_why text,
    CONSTRAINT lesson_item_progress_pkey PRIMARY KEY (id),
    CONSTRAINT lesson_item_progress_state_ck CHECK ((state = ANY (ARRAY['done'::text, 'deferred'::text, 'lost'::text])))
);
CREATE INDEX lesson_item_progress_item_ix ON v2.lesson_item_progress USING btree (item_id);
CREATE UNIQUE INDEX lesson_item_progress_uq ON v2.lesson_item_progress USING btree (item_id, section_id) WHERE (voided_at IS NULL);
ALTER TABLE v2.lesson_item_progress ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.lesson_item_progress IS 'إنجازُ بند التوزيع لكلّ فصلٍ على حدة. التوزيعُ واحدٌ للمعلّم في مادّته وصفّه، والإنجازُ بالفصل — بأمر مفرح. وحالةُ البند نفسُه مشتقّةٌ من هذي السطور لا مكتوبةٌ بيد.';

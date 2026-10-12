-- v2.standby_need
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 b331dca0951880ad8c426d54623fc386

CREATE TABLE v2.standby_need (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    weekday smallint,
    period_no smallint,
    need smallint DEFAULT 1 NOT NULL,
    note_ar text,
    set_by uuid,
    set_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT standby_need_pkey PRIMARY KEY (id),
    CONSTRAINT standby_need_ck CHECK (((need >= 0) AND (need <= 10))),
    CONSTRAINT standby_need_wd_ck CHECK (((weekday IS NULL) OR ((weekday >= 0) AND (weekday <= 6))))
);
CREATE UNIQUE INDEX standby_need_uq ON v2.standby_need USING btree (school_id, COALESCE((weekday)::integer, '-1'::integer), COALESCE((period_no)::integer, '-1'::integer));
ALTER TABLE v2.standby_need ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.standby_need IS 'عددُ معلّمي الاحتياط الذي تطلبه المدرسةُ لكلّ حصّة. الفارغُ في اليوم أو الحصّة يعني «كلَّها»، والأخصُّ يسبق. وافتراضُه واحدٌ لكلّ حصّة — وكان قبل اليوم كلَّ فراغٍ في الجدول.';

-- v2.conduct_action_items
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 5cff973a2c57eb80f59a35d25ed0400c

CREATE TABLE v2.conduct_action_items (
    id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
    action_id integer NOT NULL,
    ord smallint NOT NULL,
    kind text NOT NULL,
    text_ar text NOT NULL,
    owner_role text NOT NULL,
    conditional boolean DEFAULT false NOT NULL,
    cond_note text,
    origin text DEFAULT 'الدليل'::text NOT NULL,
    inherits_step smallint,
    excludes_kind text,
    evidence_kind text,
    CONSTRAINT conduct_action_items_pkey PRIMARY KEY (id),
    CONSTRAINT conduct_action_items_action_id_ord_key UNIQUE (action_id, ord),
    CONSTRAINT conduct_action_items_kind_check CHECK ((kind = ANY (ARRAY['record_sign'::text, 'notify_guardian'::text, 'summon_guardian'::text, 'guardian_sign'::text, 'pledge'::text, 'deduct'::text, 'compensation'::text, 'apology'::text, 'repair'::text, 'seize'::text, 'counselor'::text, 'committee'::text, 'plan'::text, 'program'::text, 'referral'::text, 'move_class'::text, 'warn_move'::text, 'edu_report'::text, 'edu_decision'::text, 'minutes'::text, 'explain_next'::text, 'follow_up'::text, 'red_crescent'::text, 'police'::text, 'report_1919'::text, 'other'::text]))),
    CONSTRAINT conduct_action_items_origin_check CHECK ((origin = ANY (ARRAY['الدليل'::text, 'البناء'::text, 'قرار مفرح'::text]))),
    CONSTRAINT conduct_action_items_text_ar_check CHECK ((btrim(text_ar) <> ''::text))
);
ALTER TABLE v2.conduct_action_items ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.conduct_action_items IS 'بنود الإجراء التربوي مفكَّكة بندًا بندًا. كل بند فعل مستقل يولّد مهمة عند الرصد. origin يميّز ما نصّ عليه الدليل عمّا أضافه البناء.';
COMMENT ON COLUMN v2.conduct_action_items.inherits_step IS 'إذا نص البند على «جميع ما ذكر في الإجراء السابق»، يحمل رقم تلك الخطوة ليُعاد توليد بنودها كاملة مع هذا الإجراء.';
COMMENT ON COLUMN v2.conduct_action_items.excludes_kind IS 'استثناء منصوص من البنود الموروثة، مثل «باستثناء نقل الطالب من الفصل».';
COMMENT ON COLUMN v2.conduct_action_items.evidence_kind IS 'نوع الإثبات الذي تُغلق به المهمة. قرار مفرح (4/10/2026): لا تُغلق مهمة بزرّ «نُفّذت» وحده.';

-- v2.period_swaps
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 0958502cf31afb5f5c20f2f052362de2

CREATE TABLE v2.period_swaps (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    on_date date NOT NULL,
    requester uuid NOT NULL,
    req_slot uuid NOT NULL,
    partner uuid NOT NULL,
    partner_slot uuid NOT NULL,
    reason_ar text,
    partner_ok boolean,
    partner_at timestamp with time zone,
    partner_note text,
    admin_ok boolean,
    admin_at timestamp with time zone,
    admin_by uuid,
    admin_note text,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT period_swaps_pkey PRIMARY KEY (id),
    CONSTRAINT period_swaps_self_ck CHECK ((requester <> partner)),
    CONSTRAINT period_swaps_slots_ck CHECK ((req_slot <> partner_slot)),
    CONSTRAINT period_swaps_status_ck CHECK ((status = ANY (ARRAY['pending'::text, 'partner_ok'::text, 'partner_no'::text, 'admin_no'::text, 'done'::text, 'cancelled'::text, 'lapsed'::text])))
);
CREATE INDEX period_swaps_day_ix ON v2.period_swaps USING btree (school_id, on_date, status);
CREATE INDEX period_swaps_slots_ix ON v2.period_swaps USING btree (req_slot, partner_slot);
ALTER TABLE v2.period_swaps ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.period_swaps IS 'تبديلُ حصّتين بين معلّمين ليومٍ واحد — لا يمسّ الجدولَ المعتمد. سلّمُه: يطلب المعلّم ← يقبل الزميل ← يعتمد الوكيلُ للشؤون التعليميّة أو المدير (س-٨-ا-١ ص٢٠١–٢٠٢: الجدولُ عملُ الوكيل واعتمادُه للمدير). ولا نصَّ للتبديل في الدليل — فالبابُ اجتهادُ مدرسة.';

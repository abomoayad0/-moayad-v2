-- v2.attendance
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 3ef492379d7fbc77801ba24f10caab0b

CREATE TABLE v2.attendance (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid NOT NULL,
    term_no smallint NOT NULL,
    student_id uuid NOT NULL,
    on_date date NOT NULL,
    state text NOT NULL,
    minutes_late smallint,
    recorded_by uuid,
    note text,
    pushed_to_noor boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    assembly_state text,
    arrived_at time without time zone,
    minutes_from_assembly smallint,
    day_status text DEFAULT 'provisional'::text NOT NULL,
    source text DEFAULT 'assistant'::text NOT NULL,
    permit_id uuid,
    recorded_role text,
    late_recorded_by uuid,
    late_recorded_role text,
    entered_by uuid,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT attendance_pkey PRIMARY KEY (id),
    CONSTRAINT attendance_student_id_on_date_key UNIQUE (student_id, on_date),
    CONSTRAINT attendance_assembly_state_check CHECK ((assembly_state = ANY (ARRAY['attended'::text, 'missed_inside'::text, 'late_inside'::text, 'not_arrived'::text]))),
    CONSTRAINT attendance_day_status_check CHECK ((day_status = ANY (ARRAY['provisional'::text, 'closed'::text]))),
    CONSTRAINT attendance_minutes_late_check CHECK (((minutes_late IS NULL) OR (minutes_late >= 0))),
    CONSTRAINT attendance_source_check CHECK ((source = ANY (ARRAY['assistant'::text, 'derived_from_periods'::text, 'guardian_portal'::text, 'system'::text]))),
    CONSTRAINT attendance_state_check CHECK ((state = ANY (ARRAY['present'::text, 'absent'::text, 'late'::text, 'permitted'::text])))
);
CREATE INDEX att_date_idx ON v2.attendance USING btree (school_id, on_date);
CREATE INDEX att_student_idx ON v2.attendance USING btree (student_id, year_id, term_no);
ALTER TABLE v2.attendance ENABLE ROW LEVEL SECURITY;
COMMENT ON COLUMN v2.attendance.pushed_to_noor IS 'هل أُدخل هذا اليوم في المنصات المعتمدة؟ م31 بند 4: «إدخال الغياب يومياً من قبل إدارة المدرسة في المنصات المعتمدة (نظام نور – منصة مدرستي)». مؤيّد يذكّر ولا يُغني عن نور.';
COMMENT ON COLUMN v2.attendance.assembly_state IS 'حالة الاصطفاف: attended حضره · missed_inside تخلّف وهو داخل المدرسة · late_inside تأخر عنه وهو داخل المدرسة · not_arrived لم يصل المدرسة بعد. واللائحة تفرّق بينها بقيد «في حال كان الطالب متواجداً داخل المدرسة».';
COMMENT ON COLUMN v2.attendance.day_status IS 'provisional قبل الإقفال — ولا حسم ولا سلّم ولا إحالة فيها. closed بعده.';
COMMENT ON COLUMN v2.attendance.source IS 'من رصد: المساعد الإداري، أو اشتقاق من سجل الحصص عند تقصيره، أو بوابة ولي الأمر، أو النظام.';
COMMENT ON COLUMN v2.attendance.recorded_role IS 'الدليل يفصل ثلاثة أدوار في س-6-ا1: الخطوة 01 حصر التأخر مالكها المناوب · والخطوة 02 حصر الغياب مالكها المساعد الإداري · والخطوة 03 إدخال الحصر في النظام مالكها مسجل المعلومات. فيُحفظ من رصد وبأي صفة، ولا يُنسب كله إلى واحد.';

-- v2.meeting_attendance
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 f883838df3726650605686f9c9d2b05e

CREATE TABLE v2.meeting_attendance (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    meeting_id uuid NOT NULL,
    person_id uuid,
    seat_role text,
    invited_as text DEFAULT 'عضو'::text NOT NULL,
    can_vote boolean DEFAULT true NOT NULL,
    state text DEFAULT 'مدعوّ'::text NOT NULL,
    excuse_ar text,
    note_ar text,
    guest_kind text,
    guest_student_id uuid,
    guest_guardian_id uuid,
    guest_name text,
    CONSTRAINT meeting_attendance_pkey PRIMARY KEY (id),
    CONSTRAINT meeting_attendance_meeting_id_person_id_key UNIQUE (meeting_id, person_id),
    CONSTRAINT meeting_attendance_guest_kind_check CHECK ((guest_kind = ANY (ARRAY['منسوب'::text, 'طالب'::text, 'وليّ أمر'::text]))),
    CONSTRAINT meeting_attendance_invited_as_check CHECK ((invited_as = ANY (ARRAY['عضو'::text, 'مستدعى'::text]))),
    CONSTRAINT meeting_attendance_state_check CHECK ((state = ANY (ARRAY['مدعوّ'::text, 'حاضر'::text, 'غائب'::text, 'معتذر'::text])))
);
ALTER TABLE v2.meeting_attendance ENABLE ROW LEVEL SECURITY;
COMMENT ON COLUMN v2.meeting_attendance.can_vote IS 'ص١٩: من يُستدعى من غير الأعضاء يشارك دون التصويت على قرارات اللجنة';

-- v2.v_obligations
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 4c21346affb13eaf1cf3b199748078e4

CREATE VIEW v2.v_obligations AS
 SELECT 'behavior'::text AS source,
    'السلوك'::text AS source_ar,
    t.id AS task_id,
    r.id AS parent_id,
    r.school_id,
    r.student_id,
    t.ord,
    t.kind,
    t.text_ar,
    t.owner_role,
    t.owner_person,
    t.status AS raw_status,
    t.is_standing,
    v2.task_state(t.status, t.is_standing) AS state,
    v2.task_state_ar(t.status, t.is_standing) AS state_ar,
    t.evidence_kind,
    t.ev_on,
    t.ev_ref,
    t.skip_reason,
    t.auto_note AS note_ar,
    NULL::date AS due_on,
    ((('م'::text || p.article_no) || ' '::text) || p.source_page) AS citation_ar,
    r.created_at,
    r.recorded_by
   FROM ((v2.behavior_tasks t
     JOIN v2.behavior_records r ON ((r.id = t.record_id)))
     JOIN v2.conduct_problems p ON ((p.id = r.problem_id)))
  WHERE (r.status <> 'voided'::text)
UNION ALL
 SELECT 'absence'::text AS source,
    'المواظبة'::text AS source_ar,
    t.id AS task_id,
    c.id AS parent_id,
    c.school_id,
    c.student_id,
    t.ord,
    t.kind,
    t.text_ar,
    t.owner_role,
    t.owner_person,
    t.status AS raw_status,
    t.is_standing,
    v2.task_state(t.status, t.is_standing) AS state,
    v2.task_state_ar(t.status, t.is_standing) AS state_ar,
    t.evidence_kind,
    t.ev_on,
    t.ev_ref,
    t.skip_reason,
    t.ev_text AS note_ar,
    NULL::date AS due_on,
    ((('م'::text || l.article_no) || ' '::text) || l.source_page) AS citation_ar,
    c.created_at,
    NULL::uuid AS recorded_by
   FROM ((v2.absence_tasks t
     JOIN v2.absence_cases c ON ((c.id = t.case_id)))
     JOIN v2.absence_ladder l ON ((l.id = c.ladder_id)))
UNION ALL
 SELECT 'mail'::text AS source,
    'الوارد'::text AS source_ar,
    f.id AS task_id,
    m.id AS parent_id,
    m.school_id,
    NULL::uuid AS student_id,
    i.ord,
    i.kind,
    i.text_ar,
    f.role_ar AS owner_role,
    f.person_id AS owner_person,
    f.status AS raw_status,
    false AS is_standing,
    v2.task_state(f.status, false) AS state,
    v2.task_state_ar(f.status, false) AS state_ar,
    'followup'::text AS evidence_kind,
    (f.done_at)::date AS ev_on,
    f.evidence_ref AS ev_ref,
    NULL::text AS skip_reason,
    f.close_note AS note_ar,
    f.due_on,
    NULL::text AS citation_ar,
    m.created_at,
    NULL::uuid AS recorded_by
   FROM ((v2.mail_followups f
     JOIN v2.mail_items i ON ((i.id = f.item_id)))
     JOIN v2.incoming_mail m ON ((m.id = i.mail_id)));

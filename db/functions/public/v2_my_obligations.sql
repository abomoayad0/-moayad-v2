-- public.v2_my_obligations(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 14fc436c4949942ebf03154e21595ac7
CREATE OR REPLACE FUNCTION public.v2_my_obligations(p_school uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; me uuid; rows jsonb; comm jsonb; ext jsonb;
        n integer; n_late integer; n_comm integer; n_ext integer;
        v_by_role text[]; v_by_comm text[]; v_teacher text[]; v_is_admin boolean;
begin
  sc := coalesce(p_school, v2.acting_school());
  if sc is null then raise exception 'لم تُعرف مدرستُك'; end if;
  perform v2.assert_my_school(sc,'ما ينتظرني');
  me := v2.current_person();
  if me is null then raise exception 'لا يُعرف صاحبُ الطلب'; end if;

  select coalesce(array_agg(m.owner_role),'{}'::text[]) into v_by_role
    from v2.task_role_map m
   where not m.is_external and m.role_keys && v2.my_post_keys();

  select coalesce(array_agg(m.owner_role),'{}'::text[]) into v_by_comm
    from v2.task_role_map m
   where not m.is_external and m.committee_key is not null
     and exists (select 1 from v2.committee_members cm
                  where cm.committee_key = m.committee_key
                    and cm.person_id = me and cm.school_id = sc
                    and (cm.ended_on is null or cm.ended_on >= current_date)
                    and (cm.year_id is null or cm.year_id in
                          (select y.id from v2.academic_years y
                            where y.school_id = sc and y.is_current)));

  v_teacher  := v2.teacher_context_roles();
  v_is_admin := ('إدارة المدرسة' = any (v_by_role));

  -- ══ ما عليك أنت: باسمك · أو بصفتك · أو لأنّك راصدُ الموقف ══
  select coalesce(jsonb_agg(jsonb_build_object(
           'source', o.source, 'source_ar', o.source_ar,
           'task', o.task_id, 'parent', o.parent_id,
           'kind', o.kind, 'text', o.text_ar,
           'owner_role', o.owner_role,
           'is_committee', false,
           'mine_by', case
             when o.owner_person = me then 'باسمك'
             when o.owner_role = any (v_by_role) then 'بصفتك — وتكليفُ الدليل «'||o.owner_role||'»'
             when o.owner_role = any (v_teacher) and o.recorded_by = me then
               'لأنّك راصدُ الموقف — وتكليفُ الدليل «'||o.owner_role||'»'
             else 'بتكليف «'||coalesce(o.owner_role,'')||'»' end,
           'state', o.state, 'state_ar', o.state_ar,
           'evidence_kind', o.evidence_kind, 'due_on', o.due_on,
           'late', (o.due_on is not null and o.due_on < current_date),
           'citation_ar', o.citation_ar, 'note_ar', o.note_ar,
           'student', (select s.full_name from v2.students s where s.id = o.student_id))
         order by (o.due_on is not null and o.due_on < current_date) desc,
                  o.due_on nulls last, o.created_at), '[]'::jsonb)
    into rows
    from v2.v_obligations o
   where o.school_id = sc and o.state = 'open'
     and ( o.owner_person = me
           or ( o.owner_person is null
                and ( o.owner_role = any (v_by_role)
                      or (o.owner_role = any (v_teacher) and o.recorded_by = me) )));

  n := jsonb_array_length(rows);

  select count(*) into n_late from v2.v_obligations o
   where o.school_id = sc and o.state='open'
     and o.due_on is not null and o.due_on < current_date
     and ( o.owner_person = me
           or ( o.owner_person is null
                and ( o.owner_role = any (v_by_role)
                      or (o.owner_role = any (v_teacher) and o.recorded_by = me) )));

  -- ══ وما على لجنتك: يُعرض ولا يُعدُّ عليك — فعملُ سبعةٍ لا يُنسب لواحد ══
  select coalesce(jsonb_agg(jsonb_build_object(
           'source', o.source, 'source_ar', o.source_ar,
           'task', o.task_id, 'parent', o.parent_id,
           'kind', o.kind, 'text', o.text_ar,
           'owner_role', o.owner_role,
           'is_committee', true,
           'committee_ar', coalesce((select c.label_ar from v2.committees c
                join v2.task_role_map m on m.committee_key = c.key
               where m.owner_role = o.owner_role limit 1), o.owner_role),
           'mine_by', 'على لجنتك وأنت عضوٌ فيها — لا عليك وحدَك',
           'state', o.state, 'state_ar', o.state_ar,
           'evidence_kind', o.evidence_kind, 'due_on', o.due_on,
           'late', (o.due_on is not null and o.due_on < current_date),
           'citation_ar', o.citation_ar, 'note_ar', o.note_ar,
           'student', (select s.full_name from v2.students s where s.id = o.student_id))
         order by o.due_on nulls last, o.created_at), '[]'::jsonb)
    into comm
    from v2.v_obligations o
   where o.school_id = sc and o.state = 'open' and o.owner_person is null
     and o.owner_role = any (v_by_comm)
     and not (o.owner_role = any (v_by_role));

  n_comm := jsonb_array_length(comm);

  -- ══ وبنودٌ على جهةٍ خارج المدرسة ══
  if v_is_admin then
    select coalesce(jsonb_agg(jsonb_build_object(
             'source', o.source, 'source_ar', o.source_ar,
             'task', o.task_id, 'kind', o.kind, 'text', o.text_ar,
             'owner_role', o.owner_role,
             'note_ar', coalesce((select m.note_ar from v2.task_role_map m
                                   where m.owner_role = o.owner_role), o.note_ar),
             'citation_ar', o.citation_ar,
             'student', (select s.full_name from v2.students s where s.id = o.student_id))
           order by o.created_at), '[]'::jsonb)
      into ext
      from v2.v_obligations o
     where o.school_id = sc and o.state = 'open' and o.owner_person is null
       and o.owner_role = any (v2.external_owner_roles());
  else ext := '[]'::jsonb; end if;
  n_ext := jsonb_array_length(ext);

  return jsonb_build_object(
    'rows', rows, 'count', n,
    'committee', comm, 'committee_count', n_comm,
    'external', ext, 'external_count', n_ext,
    'matched_by', jsonb_build_object(
       'post_keys', to_jsonb(v2.my_post_keys()),
       'by_role', to_jsonb(v_by_role),
       'by_committee', to_jsonb(v_by_comm)),
    'summary_ar', case when n = 0 then 'لا شيءَ ينتظرك الآن'
      else 'ينتظرك '||v2.ar_count(n,'بندٌ واحد','بندان','بنود','بندًا')||
           case when n_late > 0 then ' · ومنها '||
             v2.ar_count(n_late,'بندٌ واحدٌ تأخّر','بندان تأخّرا','بنودٍ تأخّرت','بندًا تأخّر')
           else '' end end,
    'committee_ar', case when n_comm = 0 then null
      else 'وعلى لجنتك '||v2.ar_count(n_comm,'بندٌ واحد','بندان','بنود','بندًا')||
           ' — تُعرض ولا تُعدُّ عليك وحدَك' end,
    'external_ar', case when n_ext = 0 then null
      else 'وعلى جهاتٍ خارج المدرسة '||
           v2.ar_count(n_ext,'بندٌ واحد','بندان','بنود','بندًا')||
           ' — ليست انتظارًا عليك، وإنّما إخراجُ خطابها' end,
    'note_ar','من السلوك والمواظبة والوارد معًا · وما كان «حالًا مستمرّةً» يُعرض ولا يُطالَب · '||
              'وما كان على لجنةٍ فهو عليها لا على كلّ عضوٍ منها · '||
              'والمطابقةُ بخريطة الأدوار لا بلفظ الدليل حرفًا');
end $function$
;

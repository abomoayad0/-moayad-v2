-- public.v2_absence_notices(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 36c3ca63c94e4659c01883de8f50d583
CREATE OR REPLACE FUNCTION public.v2_absence_notices(p_school uuid DEFAULT NULL::uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; sent jsonb; miss jsonb; n1 int; n2 int;
begin
  sc := coalesce(p_school, v2.acting_school());
  if sc is null then raise exception 'لم تُعرف مدرستُك'; end if;
  perform v2.assert_my_school(sc,'إخطاراتُ الغياب');
  perform v2.assert_role(array['principal','deputy','deputy_students','deputy_school',
      'deputy_school_students','admin_assistant','admin_assistant_students'],
      'إخطاراتُ الغياب');

  select coalesce(jsonb_agg(jsonb_build_object(
           'student', s.id, 'name', v2.fn_display_name(s.full_name),
           'grade', e.grade, 'section', e.section,
           'excused', nt.excused,
           'excuse_due_ar', case when nt.excuse_due is null then null
                                 else v2.fn_to_hijri(nt.excuse_due)||' هـ' end,
           'sent_ar', to_char(nt.sent_at,'HH24:MI')) order by e.grade, e.section, s.full_name),
         '[]'::jsonb) into sent
    from v2.absence_notices nt
    join v2.students s on s.id=nt.student_id
    left join v2.enrolments e on e.student_id=s.id and e.school_id=sc and e.status='active'
   where nt.school_id=sc and nt.on_date=p_date;

  select coalesce(jsonb_agg(jsonb_build_object(
           'student', s.id, 'name', v2.fn_display_name(s.full_name),
           'grade', e.grade, 'section', e.section,
           'why_ar', case when not exists (select 1 from v2.guardians g where g.student_id=s.id)
                          then 'لا وليَّ أمرٍ مسجَّلٌ له — فلا موضعَ للإخطار'
                          else 'غائبٌ ولم يُخطَر وليُّ أمره بعد' end)
         order by e.grade, e.section, s.full_name), '[]'::jsonb) into miss
    from v2.attendance a
    join v2.students s on s.id=a.student_id
    left join v2.enrolments e on e.student_id=s.id and e.school_id=sc and e.status='active'
   where a.school_id=sc and a.on_date=p_date and a.state='absent'
     and not exists (select 1 from v2.absence_notices nt
                      where nt.student_id=a.student_id and nt.on_date=p_date);

  n1 := jsonb_array_length(sent); n2 := jsonb_array_length(miss);

  return jsonb_build_object(
    'on_date', p_date,
    'on_date_ar', coalesce(v2.fn_to_hijri(p_date)||' هـ', p_date::text),
    'sent', sent, 'not_sent', miss,
    'counts', jsonb_build_object('sent',n1,'not_sent',n2),
    'summary_ar', case
      when n1+n2 = 0 then 'لا غائبَ اليومَ — فلا إخطار'
      when n2 = 0 then 'أُخطر '||v2.ar_count(n1,'وليُّ أمرٍ واحد','وليّا أمرٍ','أولياءِ أمور',
                          'وليَّ أمرٍ')||' · ولم يبقَ أحد'
      else 'أُخطر '||v2.ar_num(n1)||' · ويبقى '||
           v2.ar_count(n2,'غائبٌ واحدٌ لم يُخطَر وليُّه','غائبان لم يُخطَر وليّاهما',
             'غائبين لم يُخطَر أولياؤهم','غائبًا لم يُخطَر وليُّه') end,
    'citation_ar', (select 'م'||article_no||' · '||source_doc||' '||source_page
                      from v2.conduct_rules where key='attendance.daily_notify'),
    'note_ar','الإخطارُ واجبٌ يوميٌّ على إدارة المدرسة (م35) لا بندٌ في السلّم — '||
              'والسلّمُ يبدأ من اليوم الثالث، والإخطارُ من أوّل يوم');

end $function$
;

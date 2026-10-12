-- public.v2_card_my_steps(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6eaf2a664c7b749155129bcf68a3489b
CREATE OR REPLACE FUNCTION public.v2_card_my_steps(p_school uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare me uuid := v2.current_person(); sc uuid := coalesce(p_school, v2.acting_school());
        r jsonb; n_late int;
begin
  if me is null then raise exception 'لا بدّ من تسجيل الدخول'; end if;
  perform v2.assert_my_school(sc,'قراءةَ ما يُنتظر منك');

  select coalesce(jsonb_agg(jsonb_build_object(
      'step',s.id,'student',s.student_id,
      'student_ar',coalesce(v2.fn_display_name(st.full_name),'—'),
      'title_ar',s.title_ar,'kind',s.kind,
      'opened_on',s.opened_on,'due_on',s.due_on,
      'days_left',(s.due_on - current_date),
      'state_ar', case when s.due_on < current_date
          then '🔴 تجاوزت موعدَها بـ'||v2.ar_num(current_date - s.due_on)||' يومًا'
          when s.due_on = current_date then '🟠 موعدُها اليوم'
          else '🟢 بقي '||v2.ar_num(s.due_on - current_date)||' يومًا' end)
      order by s.due_on, st.full_name),'[]'::jsonb),
    count(*) filter (where s.due_on < current_date)
    into r, n_late
    from v2.card_due_steps s join v2.students st on st.id=s.student_id
   where s.school_id=sc and s.owner_person=me and s.answered_at is null;

  return jsonb_build_object('rows',r,'count',jsonb_array_length(r),'late',coalesce(n_late,0),
    'summary_ar', case when jsonb_array_length(r)=0 then 'لا شيءَ مستحقٌّ عليك الآن'
      else v2.ar_count(jsonb_array_length(r),'خطوةٌ واحدةٌ تنتظرك','خطوتان تنتظرانك',
             'خطواتٍ تنتظرك','خطوةً تنتظرك')
        ||case when coalesce(n_late,0)>0 then ' · منها '||v2.ar_num(n_late)||' تجاوزت موعدَها' else '' end end,
    'note_ar','وما تجاوز موعدَه يكشفه الجردُ — فالخطوةُ بلا موعدٍ تبقى دهرًا بلا سائل');
end $function$
;

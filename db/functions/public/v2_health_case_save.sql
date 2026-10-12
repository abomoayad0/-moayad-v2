-- public.v2_health_case_save(p_student uuid, p_kind text, p_title text, p_hint text, p_severity text, p_until date, p_private text, p_case uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 dc2514c30320ad0803707b0451c62124
CREATE OR REPLACE FUNCTION public.v2_health_case_save(p_student uuid, p_kind text, p_title text, p_hint text, p_severity text DEFAULT 'انتبه'::text, p_until date DEFAULT NULL::date, p_private text DEFAULT NULL::text, p_case uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; me uuid; nm text; cid uuid; k record;
begin
  me := v2.current_person();
  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  if sc is null then raise exception 'الطالبُ لا قيدَ فعّالَ له'; end if;
  perform v2.health_gate(sc, 'تسجيلَ حالةٍ صحيّةٍ للطالب');

  select * into k from v2.health_kinds where code=p_kind and active;
  if k.code is null then raise exception 'نوعُ الحالة غيرُ معروف — والأنواعُ في فهرس القاعدة'; end if;
  if coalesce(btrim(p_title),'')='' then raise exception 'اكتب اسمَ الحالة'; end if;
  if v2.rule_n(sc,'health_hint_required')=1 and coalesce(btrim(p_hint),'')='' then
    raise exception 'لا تُسجَّل حالةٌ بلا إرشادِ تعاملٍ للمعلّم — وهو وحدَه ما يراه';
  end if;
  if p_severity not in ('انتبه','حرج') then raise exception 'درجةُ الانتباه: انتبه أو حرج'; end if;
  if p_kind='temporary' and p_until is null then
    raise exception 'الحالةُ المؤقّتةُ يلزمها موعدُ انتهاء';
  end if;
  if p_until is not null and p_until < current_date then raise exception 'موعدُ الانتهاء قد مضى'; end if;

  select v2.fn_display_name(full_name) into nm from v2.students where id=p_student;

  if p_case is null then
    insert into v2.health_cases (school_id,student_id,kind,title_ar,teacher_hint_ar,severity,
        private_note_ar,until_on,by_person,by_role_ar,is_test)
    values (sc,p_student,p_kind,btrim(p_title),btrim(p_hint),p_severity,
        nullif(btrim(coalesce(p_private,'')),''),p_until,me,
        v2.role_ar('health_counselor'),
        coalesce((select test_mode from v2.schools where id=sc),false))
    returning id into cid;
  else
    select id into cid from v2.health_cases where id=p_case and ended_at is null;
    if cid is null then raise exception 'لا حالةَ مفتوحةٌ بهذا المُعرّف'; end if;
    update v2.health_cases
       set kind=p_kind, title_ar=btrim(p_title), teacher_hint_ar=btrim(p_hint),
           severity=p_severity, private_note_ar=nullif(btrim(coalesce(p_private,'')),''),
           until_on=p_until, reviewed_on=current_date, reviewed_by=me
     where id=cid;
  end if;

  return jsonb_build_object('case',cid,'new',p_case is null,
    'said_ar', format('%s لـ%s: «%s» — وما يراه المعلّم: «%s»',
      case when p_case is null then 'سُجّلت حالةٌ' else 'عُدّلت الحالة' end,
      coalesce(nm,'الطالب'), k.label_ar, btrim(p_hint)),
    'teacher_sees', jsonb_build_object('hint', btrim(p_hint), 'severity', p_severity),
    'hidden_ar','اسمُ الحالةِ وما كتبتَه خاصًّا لا يراهما المعلّم');
end $function$
;

-- public.v2_practice_save(p_school uuid, p_code text, p_title text, p_points numeric, p_polarity text, p_scope text, p_kind text, p_zone text, p_once_per_day boolean, p_threshold_count smallint, p_threshold_days smallint, p_escalate_to integer, p_escalate_note text, p_note text, p_ord smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1dea32667428ae182a56aece3da03ef0
CREATE OR REPLACE FUNCTION public.v2_practice_save(p_school uuid, p_code text, p_title text, p_points numeric, p_polarity text, p_scope text, p_kind text, p_zone text, p_once_per_day boolean, p_threshold_count smallint, p_threshold_days smallint, p_escalate_to integer, p_escalate_note text, p_note text, p_ord smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare cur record; newcode text;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic'],
                         'ضبط ممارسات الصفّ');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if btrim(coalesce(p_title,''))='' then raise exception 'اكتب نصَّ الممارسة'; end if;
  if coalesce(p_polarity,'') not in ('positive','negative') then
    raise exception 'الممارسةُ إيجابيّةٌ أو سلبيّة'; end if;
  if p_scope is null or not exists (select 1 from v2.practice_scopes s
        where s.key=p_scope and (s.school_id is null or s.school_id=p_school)) then
    raise exception 'مجالٌ غيرُ معروف — أضفه أوّلًا'; end if;

  select * into cur from v2.class_practices where code = p_code;

  -- جديدةٌ للمدرسة
  if cur.code is null then
    newcode := coalesce(nullif(btrim(coalesce(p_code,'')),''),
                        'sch_'||substr(md5(p_school::text||p_title||clock_timestamp()::text),1,10));
    insert into v2.class_practices(code,school_id,title_ar,points,polarity,scope,kind,zone,
        once_per_day,threshold_count,threshold_days,escalate_to,escalate_note,note_ar,ord,
        active,origin)
    values (newcode,p_school,btrim(p_title),coalesce(p_points,0),p_polarity,p_scope,
        coalesce(p_kind,'practice'),p_zone,coalesce(p_once_per_day,false),
        p_threshold_count,p_threshold_days,p_escalate_to,p_escalate_note,
        nullif(btrim(coalesce(p_note,'')),''),coalesce(p_ord,0),true,'المدرسة');
    return jsonb_build_object('ok',true,'code',newcode,'mode','أُضيفت');
  end if;

  if cur.school_id is not null and cur.school_id <> p_school then
    raise exception 'هذي الممارسةُ لمدرسةٍ أخرى'; end if;

  -- ممارسةُ المدرسة نفسِها ⇒ تُعدَّل في مكانها
  if cur.school_id = p_school then
    update v2.class_practices set
      title_ar=btrim(p_title), points=coalesce(p_points,0), polarity=p_polarity,
      scope=p_scope, kind=coalesce(p_kind,'practice'), zone=p_zone,
      once_per_day=coalesce(p_once_per_day,false),
      threshold_count=p_threshold_count, threshold_days=p_threshold_days,
      escalate_to=p_escalate_to, escalate_note=p_escalate_note,
      note_ar=nullif(btrim(coalesce(p_note,'')),''), ord=coalesce(p_ord,ord)
     where code=p_code;
    return jsonb_build_object('ok',true,'code',p_code,'mode','عُدّلت');
  end if;

  -- 🔑 مشتركةٌ ⇒ سطرُ تعديلٍ، والكودُ يبقى واحدًا
  insert into v2.practice_overrides(school_id,code,hidden,title_ar,points,polarity,scope,kind,
      zone,once_per_day,threshold_count,threshold_days,escalate_to,escalate_note,note_ar,ord,set_by)
  values (p_school,p_code,false,btrim(p_title),p_points,p_polarity,p_scope,p_kind,p_zone,
      p_once_per_day,p_threshold_count,p_threshold_days,p_escalate_to,p_escalate_note,
      nullif(btrim(coalesce(p_note,'')),''),p_ord,v2.current_person())
  on conflict (school_id,code) do update set
      hidden=false, title_ar=excluded.title_ar, points=excluded.points,
      polarity=excluded.polarity, scope=excluded.scope, kind=excluded.kind,
      zone=excluded.zone, once_per_day=excluded.once_per_day,
      threshold_count=excluded.threshold_count, threshold_days=excluded.threshold_days,
      escalate_to=excluded.escalate_to, escalate_note=excluded.escalate_note,
      note_ar=excluded.note_ar, ord=excluded.ord,
      set_by=excluded.set_by, set_at=now();
  return jsonb_build_object('ok',true,'code',p_code,'mode','عُدّلت لمدرستك');
end $function$
;

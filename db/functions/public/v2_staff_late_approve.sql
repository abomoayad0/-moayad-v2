-- public.v2_staff_late_approve(p_id uuid, p_fares_ref text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d2b127df7272b3686a6c27c3fd2fd609
CREATE OR REPLACE FUNCTION public.v2_staff_late_approve(p_id uuid, p_fares_ref text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare a record; nm text;
begin
  perform v2.assert_role(array['principal'],'اعتمادَ قرار الحسم أو التنبيه');
  select * into a from v2.staff_late_actions where id=p_id and voided_at is null;
  if a.id is null then raise exception 'لا أمرَ بهذا المعرّف'; end if;
  perform v2.assert_my_school(a.school_id,'اعتمادَ قرار الحسم أو التنبيه');
  if a.approved_at is not null then
    raise exception 'اعتُمد سلفًا في % — ومرجعُ فارس: %', a.approved_at::date,
      coalesce(a.fares_ref,'لم يُكتب'); end if;

  update v2.staff_late_actions
     set approved_by=v2.current_person(), approved_at=now(),
         fares_ref=nullif(btrim(coalesce(p_fares_ref,'')),'')
   where id=p_id;

  select v2.fn_display_name(full_name) into nm from v2.people where id=a.person_id;
  return jsonb_build_object('ok',true,'id',p_id,'kind',a.kind,
    'summary_ar', case when a.kind='deduction'
      then 'اعتُمد أمرُ الحسم لـ'||coalesce(nm,'المنسوب')||' بمقدار '||
           v2.ar_count(coalesce(a.days,0),'يومٍ واحد','يومين','أيّامٍ','يومًا')
      else 'اعتُمد التنبيهُ لـ'||coalesce(nm,'المنسوب') end,
    'fares_ref', nullif(btrim(coalesce(p_fares_ref,'')),''),
    'note_ar', case when nullif(btrim(coalesce(p_fares_ref,'')),'') is null
      then '🟠 ولم يُكتب مرجعُ فارس — والرفعُ هناك خارجُ هذا النظام، فاكتب مرجعَه ليبقى الأثر'
      else 'ومرجعُ الرفع في فارس محفوظ' end);
end $function$
;

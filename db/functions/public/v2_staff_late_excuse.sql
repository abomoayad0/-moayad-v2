-- public.v2_staff_late_excuse(p_id uuid, p_decision text, p_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 31081d95f5628e95e9b4d294b304bf7e
CREATE OR REPLACE FUNCTION public.v2_staff_late_excuse(p_id uuid, p_decision text, p_why text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare l record; v_min int; nm text;
begin
  perform v2.assert_role(array['principal'],'الحكمَ في عذرِ تأخّرِ المنسوب');
  select * into l from v2.staff_lateness where id=p_id and voided_at is null;
  if l.id is null then raise exception 'لا سجلَّ تأخّرٍ بهذا المعرّف'; end if;
  perform v2.assert_my_school(l.school_id,'الحكمَ في عذرِ تأخّرِ المنسوب');
  if p_decision not in ('accepted','rejected') then
    raise exception 'الحكمُ قبولٌ أو رفضٌ لا غير'; end if;
  v_min := v2.rule_n(l.school_id,'reason_min_chars');
  if length(btrim(coalesce(p_why,''))) < v_min then
    raise exception 'الحكمُ لا يقع بلا سببٍ مكتوبٍ — وأقلُّه % حرفًا', v2.ar_num(v_min); end if;

  update v2.staff_lateness
     set excuse_state=p_decision, excuse_ar=coalesce(excuse_ar,btrim(p_why)),
         decided_by=v2.current_person(), decided_at=now(), decision_note=btrim(p_why)
   where id=p_id;

  select v2.fn_display_name(full_name) into nm from v2.people where id=l.person_id;
  return jsonb_build_object('ok',true,'id',p_id,'decision',p_decision,
    'summary_ar', case when p_decision='accepted'
      then 'قُبل عذرُ '||coalesce(nm,'المنسوب')||' في '||l.on_date||' — فلا يُحصر تأخّرُ ذلك اليوم'
      else 'رُفض عذرُ '||coalesce(nm,'المنسوب')||' في '||l.on_date||' — فيبقى محصورًا' end,
    'note_ar','ولمدير المدرسة الحقُّ في رفض أو قبول الأعذار — '||v2.cite_of('hr.excuse_principal'));
end $function$
;

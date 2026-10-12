-- public.v2_person_rank_set(p_school uuid, p_person uuid, p_rank text, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 8310ecb8dbf1fbd02e9a69937014b83d
CREATE OR REPLACE FUNCTION public.v2_person_rank_set(p_school uuid, p_person uuid, p_rank text, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_name text; v_old text; v_per int;
begin
  perform v2.assert_my_school(p_school,'تسجيلَ رتبة منسوب');
  perform v2.assert_role(array['principal','deputy','deputy_school','deputy_academic',
    'admin_assistant','info_registrar'],'تسجيلَ رتبة منسوب');

  if btrim(coalesce(p_rank,'')) not in ('practitioner','advanced','expert') then
    raise exception 'رتبةٌ غيرُ معروفة — والمقبولُ: practitioner ممارس · advanced متقدّم · expert خبير';
  end if;

  select pe.full_name, pe.rank_key into v_name, v_old
    from v2.people pe
    join v2.assignments a on a.person_id=pe.id and a.school_id=p_school and a.ended_on is null
   where pe.id = p_person limit 1;
  if v_name is null then
    raise exception 'هذا المنسوبُ ليس على ملاك مدرستك';
  end if;

  update v2.people set rank_key = btrim(p_rank) where id = p_person;
  v_per := v2.teacher_quota(p_school, p_person);

  return jsonb_build_object('ok',true,'person',p_person,'rank',btrim(p_rank),'was',v_old,
    'quota',v_per,
    'summary_ar','صار «'||v_name||'» '||
      (select tr.label_ar from v2.teaching_ranks tr where tr.key=btrim(p_rank))
      ||' — ونصابُه '||v_per||' حصّة',
    'note_ar','والنصابُ من الدليل التنظيميّ ص١٠ (وص٤٤ للتربية الخاصّة) — لا من اجتهادٍ. '
      ||'ويُحسب في اقتراح الجدول من الآن.');
end $function$
;

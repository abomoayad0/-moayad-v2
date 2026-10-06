-- public.v2_record_amend(p_record uuid, p_place text, p_note text, p_injury boolean, p_damage boolean, p_seizure boolean, p_seizure_legal boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f2da91e5028b502763048b45c2022537
CREATE OR REPLACE FUNCTION public.v2_record_amend(p_record uuid, p_place text, p_note text, p_injury boolean, p_damage boolean, p_seizure boolean, p_seizure_legal boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r record; me uuid;
begin
  select * into r from v2.behavior_records where id=p_record;
  if r.id is null then raise exception 'الرصدةُ غيرُ موجودة'; end if;
  perform v2.assert_my_student(r.student_id,'تعديل رصدة');
  me := v2.current_person();
  if r.recorded_by is distinct from me then
    perform v2.assert_role(array['deputy_students','deputy','principal'],
      'تعديلَ رصدةِ غيرك'); end if;
  if r.status = 'voided' then raise exception 'رصدةٌ ملغاةٌ لا تُعدَّل'; end if;
  if r.created_at::date <> current_date then
    raise exception 'لا تُعدَّل رصدةٌ بعد يومها — ويُلغى ما أُخطئ فيه بسببٍ مكتوب'; end if;

  update v2.behavior_records set
    place = coalesce(nullif(btrim(coalesce(p_place,'')),''), place),
    note  = coalesce(nullif(btrim(coalesce(p_note,'')),''), note),
    has_injury = coalesce(p_injury, has_injury),
    has_damage = coalesce(p_damage, has_damage),
    has_seizure = coalesce(p_seizure, has_seizure),
    seizure_is_legal_matter = coalesce(p_seizure_legal, seizure_is_legal_matter)
   where id=p_record;
  return jsonb_build_object('ok',true,
    'note','ويُراجَع الإجراءُ إن ظهر إتلافٌ أو مضبوطاتٌ لم تُذكر عند الرصد');
end $function$
;

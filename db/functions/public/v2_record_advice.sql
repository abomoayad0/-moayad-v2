-- public.v2_record_advice(p_record uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 cc68d362a6ffba1be587c020266336b5
CREATE OR REPLACE FUNCTION public.v2_record_advice(p_record uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r record;
begin
  select br.student_id, br.advice_ar, br.occurrence_no, cp.text_ar ptext
    into r from v2.behavior_records br
    join v2.conduct_problems cp on cp.id=br.problem_id where br.id=p_record;
  if r.student_id is null then raise exception 'الرصدةُ غيرُ موجودة'; end if;
  perform v2.assert_student_or_kin(r.student_id,'نصيحة الرصدة');
  return jsonb_build_object('text',r.advice_ar,
    'occurrence_ar',v2.ord_ar(r.occurrence_no),
    'problem', rtrim(btrim(r.ptext),'.'));
end $function$
;

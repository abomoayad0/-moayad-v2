-- public.v2_committee_duty_save(p_school uuid, p_committee text, p_duty uuid, p_text text, p_cadence text, p_ord smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f1d2c4bc16168c8c2652d30a1f07b890
CREATE OR REPLACE FUNCTION public.v2_committee_duty_save(p_school uuid, p_committee text, p_duty uuid, p_text text, p_cadence text, p_ord smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare nid uuid; cur record;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy'],'ضبطَ مهامّ اللجان');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if btrim(coalesce(p_text,''))='' then raise exception 'اكتب نصَّ المهمّة'; end if;
  if p_cadence is not null and p_cadence not in
     ('مستمرّة','شهريّة','فصليّة','سنويّة','عند الحاجة') then
    raise exception 'الدوريّة: مستمرّةٌ · شهريّةٌ · فصليّةٌ · سنويّةٌ · عند الحاجة'; end if;

  if p_duty is null then
    insert into v2.committee_duties(committee_key,school_id,ord,text_ar,cadence,source_ar)
    values (p_committee,p_school,coalesce(p_ord,99),btrim(p_text),p_cadence,
        'اجتهادُ مدرسةٍ') returning id into nid;
    return jsonb_build_object('ok',true,'duty',nid,'mode','أُضيفت');
  end if;

  select * into cur from v2.committee_duties where id=p_duty;
  if cur.id is null then raise exception 'مهمّةٌ غيرُ موجودة'; end if;
  if cur.school_id is null then
    raise exception 'هذي مهمّةٌ بنصّ الدليل — تُقرأ ولا تُعدَّل'; end if;
  if cur.school_id <> p_school then raise exception 'ليست مهمّةَ مدرستك'; end if;
  update v2.committee_duties set text_ar=btrim(p_text), cadence=p_cadence,
    ord=coalesce(p_ord,ord) where id=p_duty;
  return jsonb_build_object('ok',true,'duty',p_duty,'mode','عُدّلت');
end $function$
;

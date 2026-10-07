-- public.v2_bank_save(p_school uuid, p_id uuid, p_key text, p_problem integer, p_text text, p_ord smallint, p_active boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 67b68b5da31d212f78446c3ae06add44
CREATE OR REPLACE FUNCTION public.v2_bank_save(p_school uuid, p_id uuid, p_key text, p_problem integer, p_text text, p_ord smallint, p_active boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare cur record; nid uuid;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic','counselor'],
                         'ضبطَ بنك العبارات');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if p_id is null then
    if btrim(coalesce(p_key,''))='' then raise exception 'اختر مفتاحَ العبارة'; end if;
    if btrim(coalesce(p_text,''))='' then raise exception 'اكتب العبارة'; end if;
    insert into v2.phrase_bank(school_id,bank_key,problem_id,text_ar,ord)
    values (p_school,p_key,p_problem,btrim(p_text),coalesce(p_ord,99))
    returning id into nid;
    return jsonb_build_object('ok',true,'id',nid,'mode','أُضيفت');
  end if;
  select * into cur from v2.phrase_bank where id=p_id;
  if cur.id is null then raise exception 'عبارةٌ غيرُ موجودة'; end if;
  if cur.school_id is null then
    raise exception 'هذي عبارةٌ مشتركةٌ للمجمّع — أضف عبارتَك ولا تعدّلها'; end if;
  if cur.school_id <> p_school then raise exception 'هذي العبارةُ لمدرسةٍ أخرى'; end if;
  update v2.phrase_bank set text_ar=coalesce(nullif(btrim(coalesce(p_text,'')),''),text_ar),
    ord=coalesce(p_ord,ord), active=coalesce(p_active,active) where id=p_id;
  return jsonb_build_object('ok',true,'id',p_id,'mode','عُدّلت');
end $function$
;

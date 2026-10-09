-- public.v2_entry_file(p_entry uuid, p_what text, p_evidence_path text, p_evidence_desc text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 be99bcd986116bbd916f04c16951e904
CREATE OR REPLACE FUNCTION public.v2_entry_file(p_entry uuid, p_what text, p_evidence_path text, p_evidence_desc text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare x record; o record; who text; pre text;
begin
  select * into x from v2.merit_entries where id=p_entry;
  if x.id is null then raise exception 'المشاركةُ غيرُ موجودة'; end if;
  select * into o from v2.merit_opportunities where id=x.opp_id;

  who := v2.caller_kind(x.student_id);
  if who not in ('student','guardian') then
    -- الاستشهادُ يُقرأ من v2.citations (conduct.evidence_submission) لا من نصٍّ هنا
    perform v2.assert_role(array['deputy_students','deputy','principal'],
      'ملءَ نموذج مشاركة الطالب نيابةً عنه — '||v2.cite_of('conduct.evidence_submission'));
    perform v2.assert_my_student(x.student_id,'نموذج المشاركة');
    who := 'نيابةً — وكيل شؤون الطلبة';
  else
    who := case who when 'student' then 'الطالب' else 'وليّ الأمر' end;
  end if;

  if o.state = 'مفتوحة' then raise exception 'تُملأ بعد إغلاق الفرصة'; end if;
  if x.verdict is not null then raise exception 'أُقرّت المشاركةُ سلفًا'; end if;
  if btrim(coalesce(p_what,''))='' then raise exception 'اكتب ماذا فعلتَ بالتحديد'; end if;
  if btrim(coalesce(p_evidence_desc,''))='' then raise exception 'اكتب وصفَ المرفق'; end if;
  if btrim(coalesce(p_evidence_path,''))='' then
    raise exception 'أرفق شاهدَك — المرفقُ إلزاميّ'; end if;

  pre := v2.evidence_path_for(p_entry);
  if not v2.evidence_ok(p_entry, btrim(p_evidence_path)) then
    raise exception 'المرفقُ ليس لهذي المشاركة — ارفعه إلى: %', pre; end if;

  update v2.merit_entries
     set what_ar=btrim(p_what), evidence_name=btrim(p_evidence_path),
         evidence_desc=btrim(p_evidence_desc), filed_at=now(),
         filed_by=v2.current_person(), filed_as=who
   where id=p_entry;
  return jsonb_build_object('ok',true,'by',who);
end $function$
;

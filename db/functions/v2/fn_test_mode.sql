-- v2.fn_test_mode(p_school text, p_on boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d27961f28261f5b73d05423a3dccd86b
CREATE OR REPLACE FUNCTION v2.fn_test_mode(p_school text, p_on boolean)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; nm text;
begin
  select id, name_ar into sc, nm from v2.schools where name_ar like '%'||p_school||'%' limit 1;
  if sc is null then raise exception 'لا مدرسة باسم يشبه: %', p_school; end if;
  update v2.schools set test_mode = p_on where id = sc;
  return nm || ' — وضع التجربة ' || case when p_on then 'مُشغَّل: كل ما يُرصد يُوسم تجربةً'
    else 'مُطفأ: الرصد من الآن حقيقيّ' end;
end $function$
;

-- public.v2_break_remove(p_school uuid, p_break uuid, p_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 19628537b25ade8401cbb564e664b01f
CREATE OR REPLACE FUNCTION public.v2_break_remove(p_school uuid, p_break uuid, p_why text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic'],
                         'ضبطَ فترات اليوم');
  if btrim(coalesce(p_why,''))='' then raise exception 'لا تُحذف فترةٌ بلا سببٍ مكتوب'; end if;
  update v2.break_slots set active=false,
     note_ar = coalesce(note_ar||' · ','')||'أُلغيت: '||btrim(p_why)
   where id=p_break and school_id=p_school;
  if not found then raise exception 'هذي الفترةُ ليست لمدرستك'; end if;
  return jsonb_build_object('ok',true);
end $function$
;

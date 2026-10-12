-- public.v2_role_save(p_school uuid, p_code text, p_title text, p_max smallint, p_ord smallint, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c6070f25f1d9f7a505288e51adda4bab
CREATE OR REPLACE FUNCTION public.v2_role_save(p_school uuid, p_code text, p_title text, p_max smallint DEFAULT 1, p_ord smallint DEFAULT 0, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_role(array['principal','deputy','deputy_students'],'ضبطَ أدوار الصفّ');
  perform v2.assert_my_school(p_school,'ضبطَ أدوار الصفّ');
  if btrim(coalesce(p_code,''))='' or btrim(coalesce(p_title,''))='' then
    raise exception 'الدورُ يلزمه رمزٌ واسم'; end if;
  if coalesce(p_max,1) < 1 then raise exception 'عددُ حامليه واحدٌ فأكثر'; end if;

  insert into v2.class_roles(school_id, code, title_ar, max_holders, ord, note_ar)
  values (p_school, btrim(p_code), btrim(p_title), coalesce(p_max,1), coalesce(p_ord,0),
          nullif(btrim(coalesce(p_note,'')),''))
  on conflict (school_id, code) do update
    set title_ar=excluded.title_ar, max_holders=excluded.max_holders,
        ord=excluded.ord, note_ar=excluded.note_ar;

  return jsonb_build_object('ok',true,'msg','حُفظ الدورُ «'||btrim(p_title)||'»');
end $function$
;

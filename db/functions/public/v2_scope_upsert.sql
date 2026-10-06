-- public.v2_scope_upsert(p_school uuid, p_key text, p_label text, p_ord smallint, p_active boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c82125a17e98bdf023eae177a5041d49
CREATE OR REPLACE FUNCTION public.v2_scope_upsert(p_school uuid, p_key text, p_label text, p_ord smallint, p_active boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare k text;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic'],
                         'ضبط مجالات الممارسة');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if btrim(coalesce(p_label,''))='' then raise exception 'اكتب اسمَ المجال'; end if;
  k := coalesce(nullif(btrim(coalesce(p_key,'')),''),
                'sc_'||substr(md5(p_school::text||p_label),1,10));
  if exists (select 1 from v2.practice_scopes where key=k and school_id is null) then
    raise exception 'هذا مجالٌ مشتركٌ — لا يُعدَّل من مدرسةٍ واحدة'; end if;
  insert into v2.practice_scopes(key,label_ar,school_id,ord,active)
  values (k,btrim(p_label),p_school,coalesce(p_ord,99),coalesce(p_active,true))
  on conflict (key) do update set label_ar=excluded.label_ar,
    ord=excluded.ord, active=excluded.active
   where v2.practice_scopes.school_id = p_school;
  return jsonb_build_object('ok',true,'key',k);
end $function$
;

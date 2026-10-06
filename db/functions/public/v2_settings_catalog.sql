-- public.v2_settings_catalog()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 403e091934830cbe571c6991449c802e
CREATE OR REPLACE FUNCTION public.v2_settings_catalog()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r record; n int; out_j jsonb := '[]'::jsonb;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic'],
                         'لوحة التحكّم');
  for r in select * from v2.settings_catalog order by group_ar, label_ar loop
    begin execute format('select count(*) from %s', r.table_name) into n;
    exception when others then n := null; end;
    out_j := out_j || jsonb_build_object(
      'key',r.key,'label_ar',r.label_ar,'group_ar',r.group_ar,'table_name',r.table_name,
      'editable',r.editable,'locked_why',r.locked_why,'source_ar',r.source_ar,
      'note_ar',r.note_ar,'bridge_ar',r.bridge_ar,
      'own_bridge',r.own_bridge,'allowed_cols',to_jsonb(r.allowed_cols),'rows_n',n);
  end loop;
  return out_j;
end $function$
;

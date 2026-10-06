-- public.v2_setting_rows(p_key text, p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 8de21940de31fd9a89243956a79510c1
CREATE OR REPLACE FUNCTION public.v2_setting_rows(p_key text, p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare c record; cols text; has_school boolean; is_schools boolean; q text; r jsonb; sc uuid;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic'],
                         'قراءة إعدادات المدرسة');
  select * into c from v2.settings_catalog where key=p_key;
  if c.key is null then raise exception 'إعداد غير معروف: %', p_key; end if;
  if c.own_bridge then
    raise exception '«%» يُقرأ من جسره الخاصّ: %', c.label_ar, coalesce(c.bridge_ar,'—'); end if;
  if c.pk_col is null then
    raise exception 'لم يُحدَّد مفتاحُ «%» بعد — فلا تُقرأ صفوفُه', c.label_ar; end if;

  -- 🔑 الفارغةُ = المدرسةُ النافذة
  sc := coalesce(p_school, v2.acting_school());
  if sc is null then
    raise exception 'لم تُحدَّد مدرستُك — بدّل مدرستك ثمّ أعد المحاولة'; end if;
  if not v2.my_school(sc) then raise exception 'ليست مدرستك'; end if;

  cols := format('%I as __id', c.pk_col);
  if c.ctx_cols is not null then
    select cols || coalesce((select ', '||string_agg(format('%I',x),', ') from unnest(c.ctx_cols) x),'')
      into cols; end if;
  if c.allowed_cols is not null then
    select cols || coalesce((select ', '||string_agg(format('%I',x),', ') from unnest(c.allowed_cols) x),'')
      into cols; end if;

  is_schools := (c.table_name = 'v2.schools');
  select exists (select 1 from information_schema.columns
    where table_schema=split_part(c.table_name,'.',1)
      and table_name=split_part(c.table_name,'.',2)
      and column_name='school_id') into has_school;

  q := format('select coalesce(jsonb_agg(to_jsonb(t)),''[]''::jsonb) from (select %s from %s %s limit 500) t',
        cols, c.table_name,
        case when is_schools then 'where id = '||quote_literal(sc)||'::uuid'
             when has_school then 'where school_id = '||quote_literal(sc)||'::uuid'
             else '' end);
  execute q into r;
  return jsonb_build_object('key',c.key,'label',c.label_ar,'editable',c.editable,
    'school', sc,
    'school_ar',(select name_ar from v2.schools where id=sc),
    'pk_col',c.pk_col,'id_field','__id',
    'cols',to_jsonb(coalesce(c.allowed_cols,'{}'::text[])),
    'ctx_cols',to_jsonb(coalesce(c.ctx_cols,'{}'::text[])),
    'cols_ar',coalesce(c.cols_ar,'{}'::jsonb),'rows',r);
end $function$
;

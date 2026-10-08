-- public.v2_setting_update(p_key text, p_id text, p_patch jsonb)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1f7c433e3f2a1bb187f22f9db2afb6e4
CREATE OR REPLACE FUNCTION public.v2_setting_update(p_key text, p_id text, p_patch jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare c record; sets text := ''; k text; ty text; sc uuid; act uuid;
        has_school boolean; is_schools boolean; row_exists boolean;
        st text; m text; d text; h text; ctx text;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic'],
                         'تعديل إعدادات المدرسة');
  select * into c from v2.settings_catalog where key=p_key;
  if c.key is null then raise exception 'إعداد غير معروف: %', p_key; end if;
  if not c.editable then
    raise exception 'لا يُعدَّل «%» — %. السند: %', c.label_ar, c.locked_why, c.source_ar; end if;
  if c.own_bridge then
    raise exception 'لا يُعدَّل «%» من التعديل العامّ — له جسرُه الخاصّ%',
      c.label_ar,
      case when coalesce(btrim(c.bridge_ar),'') = '' then ' في شاشته'
           else ': '||c.bridge_ar end; end if;
  if c.allowed_cols is null then
    raise exception 'لم تُحدَّد أعمدةٌ مسموحةٌ لـ«%»', c.label_ar; end if;
  if p_patch is null or p_patch='{}'::jsonb then raise exception 'لا تغيير مُرسَل'; end if;

  for k in select jsonb_object_keys(p_patch) loop
    if not (k = any(c.allowed_cols)) then
      raise exception 'لا يُعدَّل الحقلُ «%» في «%» — المسموح: %',
        coalesce(c.cols_ar->>k,k), c.label_ar,
        (select string_agg(coalesce(c.cols_ar->>x,x),' · ') from unnest(c.allowed_cols) x); end if;
    select data_type into ty from information_schema.columns
     where table_schema=split_part(c.table_name,'.',1)
       and table_name=split_part(c.table_name,'.',2) and column_name=k;
    if ty is null then raise exception 'حقلٌ غيرُ موجود: %', k; end if;
    sets := sets || case when sets='' then '' else ', ' end ||
      format('%I = nullif(($1->>%L),'''')::%s', k, k, ty);
  end loop;

  act := v2.acting_school();
  is_schools := (c.table_name='v2.schools');
  select exists (select 1 from information_schema.columns
    where table_schema=split_part(c.table_name,'.',1)
      and table_name=split_part(c.table_name,'.',2)
      and column_name='school_id') into has_school;

  if is_schools then
    sc := p_id::uuid;
  elsif has_school then
    execute format('select exists(select 1 from %s where %I::text = $1)', c.table_name, c.pk_col)
      into row_exists using p_id;
    if not row_exists then raise exception 'الصفُّ غيرُ موجود'; end if;
    execute format('select school_id from %s where %I::text = $1', c.table_name, c.pk_col)
      into sc using p_id;

    -- 🔒 صفٌّ مشتركٌ بين المدارس: لا يُعدّله إلا المالك
    if sc is null then
      if coalesce(v2.my_grant(),'') <> 'owner' then
        raise exception 'هذا الصفُّ مشتركٌ بين مدارس المجمّع — ولا يُعدّله إلا المالك. '
          'ولمدرستك أن تُنشئ نسختَها الخاصّة ثمّ تعدّلها.';
      end if;
    end if;
  end if;

  if sc is not null then
    if not v2.my_school(sc) then raise exception 'هذا الصفُّ من مدرسةٍ أخرى'; end if;
    if act is not null and act <> sc then
      raise exception 'أنت تعمل الآن في «%» — وهذا الصفُّ في «%». بدّل مدرستك لتعدّله.',
        (select name_ar from v2.schools where id=act),
        (select name_ar from v2.schools where id=sc); end if;
  end if;

  execute format('update %s set %s where %I::text = $2', c.table_name, sets, c.pk_col)
    using p_patch, p_id;
  return jsonb_build_object('ok',true,'setting',c.label_ar,'changed',p_patch);
exception when others then
  get stacked diagnostics st=returned_sqlstate, m=message_text, d=pg_exception_detail,
    h=pg_exception_hint, ctx=pg_exception_context;
  perform v2.fn_log_error(m,'v2_setting_update','لوحة التحكّم','تعديل إعداد',
    jsonb_build_object('key',p_key,'id',p_id,'patch',p_patch), st,d,h,ctx,'bridge',
    case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', m using errcode = st;
end
$function$
;

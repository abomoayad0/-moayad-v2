-- public.v2_brand_save(p_school uuid, p_logo_path text, p_logo_position text, p_show_ministry boolean, p_primary text, p_accent text, p_header text, p_footer text, p_clear text[])
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 60fd3b1e446a66389bf5cd79f79ab882
CREATE OR REPLACE FUNCTION public.v2_brand_save(p_school uuid, p_logo_path text, p_logo_position text, p_show_ministry boolean, p_primary text, p_accent text, p_header text, p_footer text, p_clear text[] DEFAULT NULL::text[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare k text;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic'],
                         'ضبطَ الهويّة البصريّة');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if p_primary is not null and p_primary !~ '^#[0-9A-Fa-f]{6}$' then
    raise exception 'اللونُ بصيغة ‎#RRGGBB'; end if;
  if p_accent is not null and p_accent !~ '^#[0-9A-Fa-f]{6}$' then
    raise exception 'اللونُ بصيغة ‎#RRGGBB'; end if;
  if p_logo_position is not null and p_logo_position not in ('right','left','center') then
    raise exception 'موضعُ الشعار: يمينٌ أو يسارٌ أو وسط'; end if;
  if p_logo_path is not null and not v2.brand_path_allows(p_logo_path,false) then
    raise exception 'الشعارُ ليس في مسار مدرستك'; end if;

  insert into v2.branding(school_id,logo_path,logo_position,show_ministry_logo,
      primary_color,accent_color,header_ar,footer_ar,updated_at)
  values (p_school,p_logo_path,coalesce(p_logo_position,'right'),
      coalesce(p_show_ministry,true),p_primary,p_accent,p_header,p_footer,now())
  on conflict (school_id) do update set
    logo_path          = coalesce(excluded.logo_path, v2.branding.logo_path),
    logo_position      = coalesce(excluded.logo_position, v2.branding.logo_position),
    show_ministry_logo = coalesce(excluded.show_ministry_logo, v2.branding.show_ministry_logo),
    primary_color      = coalesce(excluded.primary_color, v2.branding.primary_color),
    accent_color       = coalesce(excluded.accent_color, v2.branding.accent_color),
    header_ar          = coalesce(excluded.header_ar, v2.branding.header_ar),
    footer_ar          = coalesce(excluded.footer_ar, v2.branding.footer_ar),
    updated_at = now();

  if p_clear is not null then
    foreach k in array p_clear loop
      if k not in ('logo_path','primary_color','accent_color','header_ar','footer_ar') then
        raise exception 'لا يُمحى الحقلُ «%»', k; end if;
      execute format('update v2.branding set %I = null, updated_at = now() where school_id = $1', k)
        using p_school;
    end loop;
  end if;
  return jsonb_build_object('ok',true);
end $function$
;

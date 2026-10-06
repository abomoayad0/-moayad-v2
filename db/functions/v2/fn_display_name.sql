-- v2.fn_display_name(p_name text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 39d69b7fcc448bf7f57020de9dce3322
CREATE OR REPLACE FUNCTION v2.fn_display_name(p_name text)
 RETURNS text
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
declare
  s text; parts text[]; out_parts text[] := '{}'; i int; w text;
  pref text[]; n_parts int; keep_last boolean;
begin
  if p_name is null then return null; end if;
  s := btrim(regexp_replace(p_name, '\s+', ' ', 'g'));

  -- 1) حذف «بن/ابن/بنت» المنفصلة أولاً، قبل أي فصل
  if (select enabled from v2.name_rules where key='drop_bin') then
    loop
      exit when s !~ '(^|\s)(ابن|بنت|بن)(\s|$)';
      s := btrim(regexp_replace(s, '(^|\s)(ابن|بنت|بن)(\s|$)', ' ', 'g'));
      s := btrim(regexp_replace(s, '\s+', ' ', 'g'));
    end loop;
  end if;

  -- 2) فصل «بن» الملتصقة: لا تُطبّق إلا إذا سبقها ثلاثة أحرف فأكثر
  if (select enabled from v2.name_rules where key='split_glued_bin') then
    s := regexp_replace(s, '(^|\s)(\S{3,})بن(\s|$)', '\1\2 ', 'g');
    s := btrim(regexp_replace(s, '\s+', ' ', 'g'));
  end if;

  if (select enabled from v2.name_rules where key='fix_abu_hamza') then
    s := regexp_replace(s, '(^|\s)ابو(\s)', '\1أبو\2', 'g');
    s := regexp_replace(s, '(^|\s)ابا(\s)', '\1أبا\2', 'g');
  end if;

  select string_to_array(value_text,'|') into pref
    from v2.name_rules where key='compound_prefixes' and enabled;
  parts := string_to_array(s, ' ');

  i := 1;
  while i <= coalesce(array_length(parts,1),0) loop
    w := parts[i];
    if pref is not null and w = any(pref) and i < array_length(parts,1) then
      out_parts := out_parts || (w || ' ' || parts[i+1]);
      i := i + 2;
    else
      out_parts := out_parts || w;
      i := i + 1;
    end if;
  end loop;

  select value_num into n_parts from v2.name_rules where key='name_parts' and enabled;
  select enabled into keep_last from v2.name_rules where key='keep_last';

  if n_parts is null then return array_to_string(out_parts,' '); end if;
  if coalesce(array_length(out_parts,1),0) <= n_parts then return array_to_string(out_parts,' '); end if;

  if coalesce(keep_last,false) then
    return array_to_string(out_parts[1:n_parts],' ') || ' ' || out_parts[array_length(out_parts,1)];
  end if;
  return array_to_string(out_parts[1:n_parts],' ');
end $function$
;

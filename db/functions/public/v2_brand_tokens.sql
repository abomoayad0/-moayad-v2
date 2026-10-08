-- public.v2_brand_tokens()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3f76706e74562a822244900536b103f4
CREATE OR REPLACE FUNCTION public.v2_brand_tokens()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r jsonb;
begin
  if v2.my_grant() is null then
    raise exception 'لا تُقرأ رموزُ الهويّة إلّا بحسابٍ فعّال'; end if;

  select jsonb_build_object(
    'colors', (select coalesce(jsonb_agg(jsonb_build_object(
                  'key', t.token_key, 'label_ar', t.label_ar,
                  'group_ar', t.group_name, 'value', t.value, 'ord', t.ord)
                  order by t.group_name, t.ord), '[]'::jsonb)
                 from v2.brand_tokens t where t.kind = 'color'),
    'fonts',  (select coalesce(jsonb_agg(jsonb_build_object(
                  'key', t.token_key, 'label_ar', t.label_ar, 'value', t.value,
                  'is_substitute', t.is_substitute, 'original', t.original_value,
                  'note_ar', t.note) order by t.ord), '[]'::jsonb)
                 from v2.brand_tokens t where t.kind = 'font'),
    'logo_rules', (select coalesce(jsonb_agg(jsonb_build_object(
                  'key', t.token_key, 'rule_ar', t.label_ar, 'value', t.value,
                  'source', t.source_doc||' · '||t.source_page) order by t.ord), '[]'::jsonb)
                 from v2.brand_tokens t where t.kind = 'rule'),
    'source_ar', (select distinct t.source_doc from v2.brand_tokens t limit 1),
    'note_ar', 'هذي رموزُ الهويّة بسندها — تُقرأ ولا تُكتب في الكود · وما كان منها بديلًا فمذكورٌ أصلُه وسببُ استبداله')
  into r;

  return r;
end
$function$
;

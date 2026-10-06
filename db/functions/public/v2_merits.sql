-- public.v2_merits()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 08e0063bd26cb7dfcfda6bd4dc768780
CREATE OR REPLACE FUNCTION public.v2_merits()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',m.id,'group',m.group_ar,'text',m.text_ar,
    'points',m.points,'points_note',m.points_note,
    'per_participation',m.per_participation,
    'source',m.source_doc||' '||m.source_page,
    'open_points',(m.points is null))
    order by m.points desc nulls last, m.id),'[]'::jsonb)
  from v2.conduct_merits m;
$function$
;

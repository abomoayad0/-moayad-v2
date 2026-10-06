-- v2.seat_ar(p text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 fd271095095d8fe62488de1e635f8be3
CREATE OR REPLACE FUNCTION v2.seat_ar(p text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case p when 'chair' then 'رئيس اللجنة'
                when 'member' then 'عضو'
                when 'rapporteur' then 'مقرّر اللجنة'
                else coalesce(p,'—') end;
$function$
;

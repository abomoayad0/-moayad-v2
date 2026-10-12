-- v2.loyalty_week_start(p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 4597e20590181c77d072164e6f95a34e
CREATE OR REPLACE FUNCTION v2.loyalty_week_start(p_date date)
 RETURNS date
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select p_date - extract(dow from p_date)::int      -- الأسبوعُ يبدأ الأحد
$function$
;

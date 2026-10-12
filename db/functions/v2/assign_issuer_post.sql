-- v2.assign_issuer_post()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 14342e6d040f2ee8b9e924adb6584244
CREATE OR REPLACE FUNCTION v2.assign_issuer_post()
 RETURNS text
 LANGUAGE plpgsql
 STABLE
AS $function$
declare pk text;
begin
  select mp.post_key into pk from v2.my_posts() mp
   where mp.post_key in ('principal','deputy','deputy_students','deputy_school',
                         'deputy_school_students','deputy_academic')
   order by case mp.post_key when 'principal' then 1 when 'deputy' then 2
            when 'deputy_students' then 3 else 4 end
   limit 1;
  if pk is not null then return pk; end if;
  if v2.my_grant() = 'owner' then return 'owner'; end if;
  return v2.my_role();
end $function$
;

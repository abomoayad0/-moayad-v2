-- v2.fn_duty_autofill(p_school uuid, p_weekday smallint, p_zone text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 438c4d297ce680fc9e373f201ad4cc76
CREATE OR REPLACE FUNCTION v2.fn_duty_autofill(p_school uuid, p_weekday smallint, p_zone text)
 RETURNS TABLE("أُسند" text, "نصابه" integer, "مناوباته" integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare z record; need int; e record; y uuid;
begin
  perform v2.assert_role(array['principal','deputy','deputy_school'],'توزيع جدول المناوبة');
  select * into z from v2.duty_zones where school_id=p_school and key=p_zone and active;
  if z.id is null then raise exception 'موقع غير معروف: %', p_zone; end if;
  select id into y from v2.academic_years where school_id=p_school and is_current limit 1;
  select z.min_staff - count(*) into need from v2.duty_roster q
   where q.zone_id=z.id and q.weekday=p_weekday and q.ends_on is null;
  if need <= 0 then raise exception 'الموقع مكتمل سلفاً'; end if;

  for e in select * from v2.fn_duty_eligible(p_school) x
            where x.excluded_ar is null
              and x.person_id not in (select q.person_id from v2.duty_roster q
                                      where q.zone_id=z.id and q.weekday=p_weekday and q.ends_on is null)
            order by x.priority limit need loop
    insert into v2.duty_roster(school_id,year_id,weekday,zone_id,person_id,kind,note)
    values (p_school,y,p_weekday,z.id,e.person_id,
      case when z.segment='period' then 'supervision' else 'duty' end,
      'توزيع آلي بالعدل — الأولوية للأقل نصاباً (ض01 من س-15-ا1)');
    أُسند := e.person_ar; نصابه := e.periods; مناوباته := e.duties_now + 1;
    return next;
  end loop;
end $function$
;

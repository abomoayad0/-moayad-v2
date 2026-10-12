-- v2.practice_threshold_said(p_student uuid, p_code text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 bcf1b04ae8177437109ac23dc1bdb2ea
CREATE OR REPLACE FUNCTION v2.practice_threshold_said(p_student uuid, p_code text)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  select case when c.threshold_count is null then null else
    'بلغت '||v2.ar_count((select count(*) from v2.practice_records r
        where r.student_id=p_student and r.code=p_code and r.undone_at is null
          and (c.threshold_days is null or r.on_date >= current_date - c.threshold_days)),
        'مرّةً واحدة','مرّتين','مرّات','مرّة')
    ||' من '||v2.threshold_ar(c.threshold_count, c.threshold_days) end
    from v2.class_practices c where c.code = p_code
$function$
;

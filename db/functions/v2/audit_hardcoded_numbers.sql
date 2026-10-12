-- v2.audit_hardcoded_numbers()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9bd260db6e3b00089ebb6e7162ec7241
CREATE OR REPLACE FUNCTION v2.audit_hardcoded_numbers()
 RETURNS TABLE(fn text, hits text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  with f as (
    select n.nspname||'.'||p.proname fn,
           regexp_replace(
             regexp_replace(p.prosrc, '--[^' || chr(10) || ']*', ' ', 'g'),
             '''[^'']*''', '''''', 'g') src
      from pg_proc p join pg_namespace n on n.oid=p.pronamespace
     where n.nspname in ('v2','public') and p.prokind='f'
       and p.proname !~ '^audit' and p.proname !~ 'audit'
       and p.prosrc !~ 'teaching_loads' and p.prosrc !~ 'teaching_quota'
       and p.prosrc !~ 'settings_catalog' and p.prosrc !~ 'citations'
       and p.prosrc !~ 'grading_models' and p.prosrc !~ 'conduct_'
       and p.prosrc !~ 'absence_ladder' and p.prosrc !~ 'school_rules'
       and p.prosrc !~ '_rules' and p.prosrc !~ 'standby_need'
       and p.prosrc !~ 'subject_plan' and p.prosrc !~ 'study_plans'),
  m as (
    select f.fn, x[1] lit
      from f, lateral regexp_matches(f.src,
        '(?:>=|<=|>|<|=|\+|\-)\s*([1-9][0-9])(?![0-9\.])', 'g') x)
  select m.fn, string_agg(distinct m.lit, ' · ' order by m.lit),
    'رقمٌ من خانتين مكتوبٌ في جسم الدالّة ولا مرجعَ يقرؤه — فإن كان عتبةً أو سقفًا فهو نقضُ مرجع',
    'انتبه'
  from m group by m.fn
  having count(distinct m.lit) > 0
  order by 1
$function$
;

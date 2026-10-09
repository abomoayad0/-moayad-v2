-- v2.audit_citations_ranked()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 4d9b70a80ccb929ee45b3623eab7e7f6
CREATE OR REPLACE FUNCTION v2.audit_citations_ranked()
 RETURNS TABLE(fn text, page text, severity text, severity_ar text, line_no integer, line_text text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  with src as (
    select n.nspname||'.'||p.proname fn, p.prosrc,
           (p.prosrc ~ 'insert into v2\.' or p.prosrc ~ 'update v2\.') as writes
      from pg_proc p join pg_namespace n on n.oid=p.pronamespace
     where n.nspname in ('v2','public') and p.prokind='f'
       and p.proname not in ('audit_hardcoded_citations','audit_citations_ranked',
                             'page_ar','audit_duplication','cite','cite_of','cite_page')
  ), lines as (
    select s.fn, s.writes, l.ln line_no, l.txt
      from src s, lateral (
        select row_number() over () ln, t txt
          from regexp_split_to_table(s.prosrc, E'\n') t) l
     where l.txt ~ 'ص[0-9٠-٩]{1,3}'
  )
  select l.fn, m[1] page,
         case when btrim(l.txt) like '--%' then 'comment'
              when l.txt ~ 'raise exception' then 'refusal'
              when l.writes then 'row_write'
              else 'display' end,
         case when btrim(l.txt) like '--%' then 'تعليقٌ في الكود — ليس ديْنًا'
              when l.txt ~ 'raise exception' then 'رسالةُ رفضٍ — تُقال ولا تُكتب في صفّ'
              when l.writes then 'يُكتب في صفٍّ حقيقيّ — وهذا هو الخطر'
              else 'نصُّ عرضٍ — يُقرأ ولا يُخزَّن' end,
         l.line_no::int, btrim(l.txt)
    from lines l, lateral regexp_matches(l.txt,'(ص[0-9٠-٩]{1,3})','g') m
$function$
;

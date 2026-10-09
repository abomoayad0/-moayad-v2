-- v2.audit_single_bound_links()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a6c4e899200f61f3e044ecdaf98afc7e
CREATE OR REPLACE FUNCTION v2.audit_single_bound_links()
 RETURNS TABLE(tbl text, bound_to text, siblings text[], why_ar text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select c.conrelid::regclass::text,
         c.confrelid::regclass::text,
         array['v2.behavior_tasks','v2.absence_tasks','v2.mail_followups'],
         'جدولُ ربطٍ يُشير إلى جدولِ بنودٍ واحدٍ، وفي النظام ثلاثةُ جداولِ بنود — '||
         'فما يُربط من أحدها لا يُربط من الآخرين'
    from pg_constraint c
   where c.contype='f'
     and c.confrelid in ('v2.behavior_tasks'::regclass,'v2.absence_tasks'::regclass,
                         'v2.mail_followups'::regclass)
     and c.conrelid::regclass::text like '%link%' or
         (c.contype='f' and c.confrelid='v2.behavior_tasks'::regclass
          and c.conrelid::regclass::text like '%_tasks')
$function$
;

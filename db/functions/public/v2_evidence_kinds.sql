-- public.v2_evidence_kinds()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 034bb5468a2801a5267a1e793c6c676b
CREATE OR REPLACE FUNCTION public.v2_evidence_kinds()
 RETURNS TABLE(key text, label_ar text, hint_ar text, needs_date boolean, needs_text boolean, needs_file boolean, needs_ref boolean, needs_people boolean, needs_signature boolean, needs_form smallint, form_title text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select k.key,k.label_ar,k.hint_ar,k.needs_date,k.needs_text,k.needs_file,k.needs_ref,
         k.needs_people,k.needs_signature,k.needs_form,
         (select title_ar from v2.official_forms f where f.form_no=k.needs_form)
  from v2.evidence_kinds k order by k.label_ar
$function$
;

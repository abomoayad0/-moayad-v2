-- public.v2_guardian_forms()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 0f35e70ded4f15807d4ad16e8efc5c60
CREATE OR REPLACE FUNCTION public.v2_guardian_forms()
 RETURNS TABLE(inbox_id uuid, entry_id uuid, form_no smallint, title_ar text, student_ar text, class_ar text, delivered_h text, read_at timestamp with time zone, replied_at timestamp with time zone, reply text, fields_kv jsonb, signers jsonb, signed jsonb, needs_sign boolean, needs_reply boolean, reply_options jsonb, source text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
select fi.id, e.id, e.form_no, f.title_ar,
 v2.fn_display_name(s.full_name), v2.grade_ar(en.grade)||' — '||en.section,
 v2.fn_to_hijri(fi.delivered_at::date)||' هـ', fi.read_at, fi.replied_at, fi.reply,
 v2.fn_form_kv(e.form_no, v2.fn_form_core(e.form_no, e.student_id, e.record_id), e.data),
 to_jsonb(f.signers),
 coalesce((select jsonb_agg(g.signer_ar) from v2.form_signatures g where g.entry_id=e.id),'[]'::jsonb),
 ('ولي الأمر' = any (f.signers)) and not exists
   (select 1 from v2.form_signatures g2 where g2.entry_id=e.id and g2.signer_ar='ولي الأمر'),
 exists (select 1 from v2.form_schema fs where fs.form_no=e.form_no and fs.key='guardian_reply')
   and fi.replied_at is null,
 coalesce((select to_jsonb(fs.options) from v2.form_schema fs
   where fs.form_no=e.form_no and fs.key='guardian_reply'),'[]'::jsonb),
 f.source_doc||' · '||f.source_page
from v2.form_inbox fi
join v2.form_entries e on e.id=fi.entry_id
join v2.official_forms f on f.form_no=e.form_no
join v2.students s on s.id=e.student_id
join v2.enrolments en on en.student_id=s.id and en.status='active'
where fi.to_kind='guardian'
  and fi.guardian_id in (select id from v2.guardians where user_id=auth.uid() and portal_active)
  and e.status='final'
order by fi.delivered_at desc
$function$
;

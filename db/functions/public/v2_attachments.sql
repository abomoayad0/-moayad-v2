-- public.v2_attachments(p_student uuid, p_kind text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 810525e17fa9781f3db9b51ef417d1cf
CREATE OR REPLACE FUNCTION public.v2_attachments(p_student uuid, p_kind text DEFAULT NULL::text)
 RETURNS TABLE(id uuid, kind text, kind_ar text, file_name text, mime text, size_kb integer, storage_path text, note text, uploaded_role text, created_h text, created_at timestamp with time zone)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  if exists (select 1 from v2.guardians where user_id=auth.uid() and portal_active and student_id=p_student)
   then perform v2.assert_my_child(p_student,'قراءة المرفقات');
   else perform v2.assert_my_student(p_student,'قراءة المرفقات'); end if;
  return query select a.id, a.kind,
    case a.kind when 'excuse' then 'عذر' when 'pledge' then 'تعهّد'
                when 'medical' then 'تقرير طبي' else 'أخرى' end,
    a.file_name, a.mime, a.size_kb, a.storage_path, a.note, a.uploaded_role,
    v2.fn_to_hijri(a.created_at::date)||' هـ', a.created_at
   from v2.attachments a
   where a.student_id=p_student and (p_kind is null or a.kind=p_kind)
   order by a.created_at desc;
end $function$
;

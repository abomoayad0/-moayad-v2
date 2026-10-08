-- public.v2_my_form_inbox()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5734cbf834072cfad255efe3bc3e1911
CREATE OR REPLACE FUNCTION public.v2_my_form_inbox()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare me uuid; stu uuid; r jsonb;
begin
  if auth.uid() is null then
    raise exception 'لا يُفتح الصندوقُ بلا حساب'; end if;

  -- الطالبُ بحسابه
  select s.id into stu from v2.students s
   where s.user_id = auth.uid() and coalesce(s.portal_active,false);

  -- والمنسوبُ بشخصه
  if stu is null then
    if v2.my_grant() is null then
      raise exception 'لا حسابَ فعّالٌ لك'; end if;
    me := v2.current_person();
    if me is null then
      raise exception 'حسابُك غيرُ مربوطٍ بشخصٍ في النظام'; end if;
  end if;

  select coalesce(jsonb_agg(x order by x->>'delivered_at' desc), '[]'::jsonb)
    into r
  from (
    select jsonb_build_object(
      'inbox', i.id,
      'entry', e.id,
      'to_kind', i.to_kind,
      'to_kind_ar', case i.to_kind
                      when 'counselor' then 'إليك سرًّا — الموجّه الطلابيّ'
                      when 'committee' then 'إليك سرًّا — عضوُ لجنة التوجيه'
                      when 'student'   then 'إليك — الطالب'
                      else i.to_kind end,
      'form_no', e.form_no,
      'title_ar', case when e.status = 'void'
                       then '(مسحوب) '||f.title_ar||' — والسببُ: '||coalesce(e.void_reason,'لم يُكتب سبب')
                       else f.title_ar end,
      'withdrawn', (e.status = 'void'),
      'is_secret', coalesce(f.is_secret,false),
      'student', e.student_id,
      'student_ar', v2.fn_display_name(s.full_name),
      'class_ar', v2.grade_ar(en.grade)||' — '||en.section,
      'delivered_at', i.delivered_at,
      'delivered_h', v2.fn_to_hijri(i.delivered_at::date)||' هـ',
      'read_at', i.read_at,
      'is_new', (i.read_at is null),
      'fields_kv', v2.fn_form_kv(e.form_no,
                      v2.fn_form_core(e.form_no, e.student_id, e.record_id), e.data),
      'signers', to_jsonb(f.signers),
      'signed', coalesce((select jsonb_agg(g.signer_ar) from v2.form_signatures g
                           where g.entry_id = e.id), '[]'::jsonb),
      'source', f.source_doc||' · '||f.source_page,
      'record', e.record_id,
      'is_test', coalesce(e.is_test,false)) as x
    from v2.form_inbox i
    join v2.form_entries e on e.id = i.entry_id
    join v2.official_forms f on f.form_no = e.form_no
    join v2.students s on s.id = e.student_id
    join v2.enrolments en on en.student_id = s.id and en.status='active'
   where e.status in ('final','void')
     and (
       -- 🔒 الطالبُ يرى ما وُجّه إليه وحدَه
       (stu is not null and i.to_kind = 'student' and i.student_id = stu)
       -- 🔒 والمنسوبُ يرى ما وُجّه إلى شخصه — لا ما وُجّه إلى دوره
       or (stu is null and i.to_kind in ('counselor','committee') and i.person_id = me)
     )
  ) q;

  return jsonb_build_object(
    'rows', r,
    'count', jsonb_array_length(r),
    'unread', (select count(*) from jsonb_array_elements(r) e2
                where (e2->>'is_new')::boolean),
    'who_ar', case when stu is not null then 'صندوقُ الطالب' else 'صندوقُك' end,
    'note_ar', 'ما وُصف بالسرّيّة لا يُعرض لغير من وُجّه إليه — ولا يُنقل عنه');
end
$function$
;

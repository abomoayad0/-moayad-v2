-- public.v2_form_sign(p_entry uuid, p_signer text, p_signed boolean, p_refuse_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c29f436b027f58d90bb1ad9a43461cdd
CREATE OR REPLACE FUNCTION public.v2_form_sign(p_entry uuid, p_signer text, p_signed boolean DEFAULT true, p_refuse_reason text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare e record; gid uuid; sgs text[];
begin
  select * into e from v2.form_entries where id=p_entry;
  if e.id is null then raise exception 'النموذج غير موجود'; end if;
  if e.status='void' then raise exception 'النموذج مُلغًى'; end if;
  if e.status<>'final' then raise exception 'لا يُوقَّع نموذج قبل اعتماده'; end if;

  -- ③ الملكية أولًا
  select id into gid from v2.guardians where user_id=auth.uid() and portal_active and student_id=e.student_id;
  if gid is not null then
    if p_signer <> 'ولي الأمر' then raise exception 'لا توقّع إلا بصفتك: ولي الأمر'; end if;
    if not exists (select 1 from v2.form_inbox x where x.entry_id=p_entry and x.guardian_id=gid) then
      raise exception 'هذا النموذج ليس في صندوقك'; end if;
  else
    perform v2.assert_my_school(e.school_id,'التوقيع على النموذج');
    -- ② الموظف لا يوقّع عن وليّ الأمر، لكنه يوثّق امتناعه
    if p_signer='ولي الأمر' and p_signed then
      raise exception 'توقيع ولي الأمر يكون منه في بوّابته — وللمدرسة أن توثّق امتناعه بسبب مكتوب'; end if;
    if p_signer='ولي الأمر' and not p_signed then
      perform v2.assert_role(array['deputy_students','deputy','principal','counselor','admin_assistant'],
        'توثيق امتناع ولي الأمر'); end if;
  end if;

  select signers into sgs from v2.official_forms where form_no=e.form_no;
  if not (p_signer = any (sgs)) then
    raise exception '«%» ليس من موقّعي هذا النموذج. والموقّعون: %',
      p_signer, array_to_string(sgs,' · '); end if;
  if not p_signed and btrim(coalesce(p_refuse_reason,''))='' then
    raise exception 'الامتناع عن التوقيع لا يقع بلا سبب مكتوب'; end if;
  if exists (select 1 from v2.form_signatures g where g.entry_id=p_entry and g.signer_ar=p_signer) then
    raise exception 'وُقّع عن «%» سلفًا على هذا النموذج', p_signer; end if;

  insert into v2.form_signatures(entry_id,signer_ar,person_id,guardian_id,student_id,
    signed,signed_at,refused,refuse_reason,channel)
  values (p_entry,p_signer,case when gid is null then v2.current_person() end,gid,e.student_id,
    p_signed, case when p_signed then now() end, not p_signed, p_refuse_reason,
    case when gid is null then 'in_person' else 'portal' end);
  return jsonb_build_object('ok',true,'signer',p_signer,'signed',p_signed,
    'remaining', (select coalesce(jsonb_agg(s), '[]'::jsonb) from unnest(sgs) s
                  where s not in (select signer_ar from v2.form_signatures where entry_id=p_entry)));
end $function$
;

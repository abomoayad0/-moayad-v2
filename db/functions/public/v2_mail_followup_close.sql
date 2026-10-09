-- public.v2_mail_followup_close(p_followup uuid, p_note text, p_evidence text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 62b251617de6307bdaadf8a08b0a1c86
CREATE OR REPLACE FUNCTION public.v2_mail_followup_close(p_followup uuid, p_note text, p_evidence text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare f record; m record; v_me uuid; n_rem integer;
begin
  select fu.*, i.mail_id into f from v2.mail_followups fu
    join v2.mail_items i on i.id = fu.item_id where fu.id = p_followup;
  if f.id is null then raise exception 'المتابعةُ غيرُ موجودة'; end if;
  select * into m from v2.incoming_mail where id = f.mail_id;
  perform v2.assert_my_school(m.school_id,'إقفال متابعة الوارد');
  v_me := v2.current_person();
  if f.person_id is not null and f.person_id <> v_me then
    raise exception 'هذي متابعةُ غيرك — ولكلّ موجَّهٍ إليه متابعتُه · '
      'وإن أردتَ إقفالَها عنه فحوّلها إليك بسببٍ مكتوب';
  end if;
  if f.status = 'done' then raise exception 'أُقفلت سلفًا'; end if;
  if coalesce(btrim(p_note),'') = '' then
    raise exception 'الإقفالُ يلزمه ما يُكتب فيه — فما الذي تمّ؟';
  end if;

  update v2.mail_followups set status='done', done_at=now(), done_by=v_me,
      close_note=btrim(p_note), evidence_ref=nullif(btrim(p_evidence),'')
   where id = p_followup;

  select count(*) into n_rem from v2.mail_items i
    join v2.mail_followups fu on fu.item_id=i.id
   where i.mail_id = f.mail_id and fu.status <> 'done';

  if n_rem = 0 then
    update v2.incoming_mail set status='in_progress' where id=f.mail_id and status='directed';
  end if;

  perform v2.log_action(m.school_id,null,'mail_followup_done','أُقفلت متابعةُ وارد',
    'mail_followups',p_followup,'{}'::jsonb);

  return jsonb_build_object('ok',true,'remaining',n_rem,
    'note_ar','أُقفلت متابعتُك وكُتب ما تمّ'||
      case when n_rem > 0 then ' · وبقي '||
        v2.ar_count(n_rem,'متابعةٌ واحدة','متابعتان','متابعات','متابعةً')||' على هذا الوارد'
      else ' · ولا متابعةَ بقيت على هذا الوارد' end);
end $function$
;

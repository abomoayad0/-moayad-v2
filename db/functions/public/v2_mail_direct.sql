-- public.v2_mail_direct(p_mail uuid, p_items jsonb)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e0994d37dbe9724d3c71af68b2e93307
CREATE OR REPLACE FUNCTION public.v2_mail_direct(p_mail uuid, p_items jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare m record; it jsonb; tg jsonb; iid uuid; v_ord smallint := 0;
        n_items integer := 0; n_person integer := 0; n_pending integer := 0;
        v_due date; v_kind text; v_start date; v_end date;
begin
  perform v2.assert_role(array['principal','deputy','deputy_students',
      'admin_assistant','admin_assistant_students'],'توجيه الوارد');
  select * into m from v2.incoming_mail where id=p_mail;
  if m.id is null then raise exception 'الواردُ غيرُ موجود'; end if;
  perform v2.assert_my_school(m.school_id,'توجيه الوارد');
  if m.secrecy <> 'عادي' and not v2.may_read_secret_mail() then
    raise exception 'هذا واردٌ % — ولا يُوجّهه إلّا من يحقُّ له قراءتُه', m.secrecy;
  end if;
  if m.status = 'closed' then raise exception 'الواردُ مُقفلٌ — ولا يُوجَّه بعد إقفاله'; end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'لا بندَ في الطلب — والتوجيهُ يكون ببنودٍ: [{"text":"…","kind":"تكليف","targets":[…]}]';
  end if;

  select coalesce(max(ord),0) into v_ord from v2.mail_items where mail_id=p_mail;

  for it in select * from jsonb_array_elements(p_items) loop
    if coalesce(btrim(it->>'text'),'') = '' then
      raise exception 'بندٌ بلا نصّ — ولا يُوجَّه ما لا يُقرأ';
    end if;
    v_kind := coalesce(it->>'kind','تكليف');
    if v_kind not in ('تكليف','إبلاغ بالعلم') then
      raise exception 'نوعُ البند «%» غيرُ معروف — وهما: تكليف · إبلاغ بالعلم', v_kind;
    end if;
    v_start := nullif(it->>'starts_on','')::date;
    v_end   := nullif(it->>'ends_on','')::date;
    v_ord := v_ord + 1;

    insert into v2.mail_items(mail_id,ord,text_ar,kind,starts_on,ends_on,
        dates_source,proposed_by,approved,approved_by,approved_at)
    values (p_mail,v_ord,btrim(it->>'text'),v_kind,v_start,v_end,
        case when v_start is not null or v_end is not null then 'من المدير' else 'من المدير' end,
        'يدوي',true,v2.current_person(),now())
    returning id into iid;
    n_items := n_items + 1;

    if it->'targets' is null or jsonb_typeof(it->'targets') <> 'array'
       or jsonb_array_length(it->'targets') = 0 then
      raise exception 'بندٌ بلا جهةٍ يُوجَّه إليها — «%»', left(btrim(it->>'text'),40);
    end if;

    for tg in select * from jsonb_array_elements(it->'targets') loop
      if coalesce(tg->>'kind','') not in
         ('person','persons','role','assignment','all_staff','students','guardians') then
        raise exception 'جهةُ التوجيه «%» غيرُ معروفة', coalesce(tg->>'kind','بلا نوع');
      end if;

      insert into v2.mail_targets(item_id,target_kind,person_id,role_ar,assignment_ar,
          scope_note,pending_expansion,pending_note)
      values (iid, tg->>'kind', nullif(tg->>'person','')::uuid,
          nullif(btrim(tg->>'role'),''), nullif(btrim(tg->>'assignment'),''),
          nullif(btrim(tg->>'scope'),''),
          (tg->>'kind') not in ('person','persons'),
          case when (tg->>'kind') not in ('person','persons')
               then 'جهةٌ عامّةٌ لم تُفصَّل بأسماء — فلا متابعةَ فرديّةً عليها حتّى تُفصَّل' end);

      if (tg->>'kind') in ('person','persons') then
        if nullif(tg->>'person','') is null then
          raise exception 'توجيهٌ لشخصٍ بلا اسمِه';
        end if;
        v_due := coalesce(nullif(tg->>'due_on','')::date, v_end);
        insert into v2.mail_followups(item_id,person_id,role_ar,status,due_on)
        values (iid, (tg->>'person')::uuid, nullif(btrim(tg->>'role'),''), 'open', v_due);
        n_person := n_person + 1;
      else
        n_pending := n_pending + 1;
      end if;
    end loop;
  end loop;

  update v2.incoming_mail set status='directed', directed_by=v2.current_person(), directed_at=now()
   where id=p_mail and status='new';

  perform v2.log_action(m.school_id,null,'mail_direct','وُجّه واردٌ',
    'incoming_mail',p_mail, jsonb_build_object('items',n_items,'persons',n_person));

  return jsonb_build_object('ok',true,
    'items',n_items,'followups',n_person,'pending',n_pending,
    'note_ar','وُجّه الواردُ بـ'||v2.ar_count(n_items,'بندٍ واحد','بندين','بنود','بندًا')||
      case when n_person > 0 then ' · وفُتحت '||
        v2.ar_count(n_person,'متابعةٌ واحدة','متابعتان','متابعات','متابعةً')||' بأسماء أصحابها'
      else '' end||
      case when n_pending > 0 then ' · و'||
        v2.ar_count(n_pending,'جهةٌ عامّةٌ واحدةٌ لم تُفصَّل بأسماء',
                    'جهتان عامّتان لم تُفصَّلا بأسماء','جهاتٍ عامّةٍ لم تُفصَّل بأسماء',
                    'جهةً عامّةً لم تُفصَّل بأسماء')||
        ' — فلا متابعةَ فرديّةً عليها، ولا أُوهمك بأنّها متابَعة'
      else '' end);
end $function$
;

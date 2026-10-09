-- public.v2_outgoing_create(p_subject text, p_to_entity text, p_body text, p_kind text, p_secrecy text, p_needs_reply boolean, p_reply_due date, p_reply_to_mail uuid, p_ref_table text, p_ref_id uuid, p_tasks uuid[])
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e368eb1031008d03adb973586bdadad8
CREATE OR REPLACE FUNCTION public.v2_outgoing_create(p_subject text, p_to_entity text, p_body text DEFAULT NULL::text, p_kind text DEFAULT 'letter'::text, p_secrecy text DEFAULT 'عادي'::text, p_needs_reply boolean DEFAULT false, p_reply_due date DEFAULT NULL::date, p_reply_to_mail uuid DEFAULT NULL::uuid, p_ref_table text DEFAULT NULL::text, p_ref_id uuid DEFAULT NULL::uuid, p_tasks uuid[] DEFAULT NULL::uuid[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; yr uuid; mid uuid; n integer := 0; t record; v_due date; v_days smallint;
        v_auto boolean := false;
        msg text; st text; d text; h text; ctx text;
begin
  perform v2.assert_role(array['principal','deputy','deputy_students',
      'admin_assistant','admin_assistant_students'],'إنشاء خطابٍ صادر');
  sc := v2.acting_school();
  if sc is null then raise exception 'لم تُعرف مدرستُك — فلا يُعرف سجلُّ الصادر'; end if;
  perform v2.assert_my_school(sc,'إنشاء خطابٍ صادر');
  if coalesce(btrim(p_subject),'') = '' then raise exception 'موضوعُ الخطاب لا يُترك فارغًا'; end if;
  if coalesce(btrim(p_to_entity),'') = '' then raise exception 'الجهةُ المرسلُ إليها لا تُترك فارغةً'; end if;

  select outgoing_reply_days into v_days from v2.conduct_school_rules where school_id = sc;
  v_due := p_reply_due;
  if p_needs_reply and v_due is null and v_days is not null then
    v_due := v2.workdays_after(sc, current_date, v_days);
    v_auto := true;
  end if;
  if p_needs_reply and v_due is null then
    raise exception 'إن كان الخطابُ ينتظر جوابًا فلا بدَّ من موعدٍ يُراجَع عليه — '
      'ولا أصلَ مضبوطٌ في لوحة التحكّم';
  end if;

  select id into yr from v2.academic_years where school_id = sc and is_current limit 1;

  insert into v2.outgoing_mail(school_id,year_id,subject_ar,body_ar,to_entity,kind,secrecy,
      reply_to_mail,ref_table,ref_id,prepared_by,needs_reply,reply_due_on)
  values (sc,yr,btrim(p_subject),p_body,btrim(p_to_entity),p_kind,p_secrecy,
      p_reply_to_mail,p_ref_table,p_ref_id,v2.current_person(),p_needs_reply,
      case when p_needs_reply then v_due end)
  returning id into mid;

  if p_tasks is not null then
    for t in select bt.id, bt.kind from v2.behavior_tasks bt
              join v2.behavior_records r on r.id = bt.record_id
             where bt.id = any(p_tasks) and r.school_id = sc loop
      insert into v2.outgoing_links(mail_id,source,source_id,on_event)
      values (mid, 'behavior', t.id, case when t.kind = 'edu_decision' then 'replied' else 'sent' end)
      on conflict do nothing;
      update v2.behavior_tasks set auto_note =
        'أُدرج في خطابٍ صادرٍ قيدَ الإعداد — '||btrim(p_subject)||
        case when t.kind = 'edu_decision'
             then ' · ولا يُقفل هذا البندُ إلّا بجواب الجهة'
             else ' · ويُقفل بخروج الخطاب' end
       where id = t.id;
      n := n + 1;
    end loop;

    for t in select ab.id, ab.text_ar, c.escalation_halted, c.halt_reason
              from v2.absence_tasks ab
              join v2.absence_cases c on c.id = ab.case_id
             where ab.id = any(p_tasks) and c.school_id = sc loop
      if coalesce(t.escalation_halted,false) then
        raise exception '%', 'التصعيدُ موقوفٌ في هذه الحالة — '||
          coalesce(t.halt_reason,'بغير سببٍ مكتوب')||
          ' · فلا يُحمل بندُها على خطابٍ إلى الجهات';
      end if;
      insert into v2.outgoing_links(mail_id,source,source_id,on_event)
      values (mid, 'absence', t.id, 'sent') on conflict do nothing;
      update v2.absence_tasks set ev_text =
        'أُدرج في خطابٍ صادرٍ قيدَ الإعداد — '||btrim(p_subject)||' · ويُقفل بخروج الخطاب'
       where id = t.id;
      n := n + 1;
    end loop;
  end if;

  perform v2.log_action(sc,null,'outgoing_create','أُنشئ خطابٌ صادر','outgoing_mail',mid,
    jsonb_build_object('subject',btrim(p_subject),'to',btrim(p_to_entity),'tasks',n));

  return v2.outgoing_card(mid) || jsonb_build_object('ok', true,
    'note_ar', 'أُنشئت المسوّدةُ بلا رقمِ صادر — والرقمُ يُعطى حين يُوقّعها المدير'||
      case when v_auto
        then ' · وموعدُ المراجعة '||v2.fn_to_hijri(v_due)||' هـ من أصل '||
             v2.ar_count(v_days,'يومِ عملٍ واحد','يومَي عمل','أيّامِ عمل','يومَ عمل')||
             ' · ولك تعديلُه'
        else '' end||
      case when n > 0 then ' · وربطتُ بها '||
        v2.ar_count(n,'بندًا واحدًا','بندين','بنود','بندًا')||' من السلّم' else '' end);
exception when others then
  get stacked diagnostics st=returned_sqlstate, msg=message_text, d=pg_exception_detail,
    h=pg_exception_hint, ctx=pg_exception_context;
  perform v2.fn_log_error(msg,'v2_outgoing_create','المراسلات','إنشاء صادر',
    jsonb_build_object('subject',p_subject,'to',p_to_entity),st,d,h,ctx,'bridge',
    case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', msg using errcode = st;
end $function$
;

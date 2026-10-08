-- public.v2_record_void(p_record uuid, p_reason text, p_confirm text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 568f34868342b89a1ca119b8df9aeacd
CREATE OR REPLACE FUNCTION public.v2_record_void(p_record uuid, p_reason text, p_confirm text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare
  r record; me uuid; f record; g record;
  v_n_later int; v_later text;
  v_restore numeric := 0; v_vetoed int := 0; v_forms int := 0; v_tasks int := 0;
  v_ev uuid; v_told boolean := false;
begin
  select br.*, cp.text_ar problem_ar, cp.degree_no
    into r
    from v2.behavior_records br
    join v2.conduct_problems cp on cp.id = br.problem_id
   where br.id = p_record;
  if r.id is null then raise exception 'الرصدةُ غيرُ موجودة'; end if;

  perform v2.assert_my_student(r.student_id,'إلغاءَ رصدة');
  me := v2.current_person();

  if r.recorded_by is distinct from me or r.created_at::date <> current_date then
    perform v2.assert_role(array['deputy_students','deputy','principal'],
      'إلغاءَ رصدةِ غيرك أو إلغاءَها بعد يومها');
  end if;

  if r.status = 'voided' then
    raise exception 'أُلغيت هذي الرصدةُ سلفًا — والسببُ: %', coalesce(r.void_reason,'—'); end if;
  if btrim(coalesce(p_reason,'')) = '' then
    raise exception 'لا تُلغى رصدةٌ بلا سببٍ مكتوب — فالسببُ هو شاهدُ الإلغاء، ويبقى في الملفّ'; end if;

  -- 🔑 من الآخر إلى الأوّل
  select count(*),
         string_agg('الواقعةُ '||v2.ord_ar(x.occurrence_no)||
                    ' ('||to_char(x.occurred_on,'YYYY-MM-DD')||')',
                    ' · ' order by x.occurrence_no desc)
    into v_n_later, v_later
    from v2.behavior_records x
   where x.student_id = r.student_id and x.problem_id = r.problem_id
     and x.year_id = r.year_id and x.status <> 'voided'
     and x.occurrence_no > r.occurrence_no;

  if v_n_later > 0 then
    raise exception 'لا تُلغى هذي قبل ما بعدها — فترقيمُ التكرارات وخطواتُ السلّم مبنيّةٌ عليها، وما وقع عليها من خطاباتٍ وحسمٍ لا يُنقض صامتًا · أَلغِ أوّلًا: %',
      v_later;
  end if;

  if btrim(coalesce(p_confirm,'')) <> 'أُلغي' then
    raise exception 'بالإلغاء تُردُّ الدرجاتُ المحسومةُ وتُسحب النماذجُ الخارجةُ ويُعلَم وليُّ الأمر بالسحب — اكتب «أُلغي» لتأكيده';
  end if;

  update v2.behavior_records
     set status = 'voided', voided_by = me, void_reason = btrim(p_reason)
   where id = p_record;

  select coalesce(sum(-l.points),0) into v_restore
    from v2.behavior_ledger l where l.record_id = p_record and l.kind = 'deduction';

  insert into v2.behavior_ledger(school_id,year_id,term_no,student_id,kind,points,record_id,reason,by_person)
  select l.school_id, l.year_id, l.term_no, l.student_id, 'veto', -l.points, p_record,
         'نقضُ الحسم بإلغاء الرصدة: '||btrim(p_reason), me
    from v2.behavior_ledger l
   where l.record_id = p_record and l.kind = 'deduction';
  get diagnostics v_vetoed = row_count;

  update v2.behavior_tasks
     set status = 'skipped', skip_reason = 'أُلغيت الرصدةُ: '||btrim(p_reason),
         done_at = now(), done_by = me
   where record_id = p_record and status = 'open';
  get diagnostics v_tasks = row_count;

  for f in select fe.id from v2.form_entries fe
            where fe.record_id = p_record and fe.status <> 'void' loop
    update v2.form_entries
       set status = 'void', void_reason = 'أُلغيت الرصدةُ: '||btrim(p_reason), updated_at = now()
     where id = f.id;
    v_forms := v_forms + 1;
  end loop;

  if exists (select 1 from v2.form_inbox i
              join v2.form_entries fe on fe.id = i.entry_id
             where fe.record_id = p_record and i.guardian_id is not null) then
    insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
        ref_table,ref_id,visible_to,is_test)
    values (r.school_id,'restore',current_date,r.student_id,
      'سُحبت رصدةٌ سلوكيّةٌ وما خرج عليها',
      'أُلغيت الرصدةُ المدوّنةُ في '||to_char(r.occurred_on,'YYYY-MM-DD')||
        ' («'||rtrim(btrim(r.problem_ar),'.')||'») — والسببُ: '||btrim(p_reason)||
        ' · وما خرج عليها من نماذجَ مسحوبٌ، وما حُسم من درجاتٍ مردودٌ.',
      'behavior_records',p_record,'all',coalesce(r.is_test,false))
    returning id into v_ev;

    for g in select id from v2.guardians where student_id = r.student_id loop
      insert into v2.event_deliveries(event_id,channel,to_guardian)
      values (v_ev,'guardian_portal',g.id),(v_ev,'whatsapp',g.id);
    end loop;
    v_told := true;
  end if;

  perform v2.log_action(r.school_id, r.student_id, 'record_void',
    'أُلغيت رصدةٌ سلوكيّة', 'behavior_records', p_record,
    jsonb_build_object('reason', btrim(p_reason), 'restored', v_restore,
                       'forms_voided', v_forms, 'tasks_skipped', v_tasks));

  return jsonb_build_object(
    'ok', true,
    'record', p_record,
    'restored', v_restore,
    'veto_rows', v_vetoed,
    'forms_voided', v_forms,
    'tasks_skipped', v_tasks,
    'guardian_told', v_told,
    'note_ar', 'أُلغيت الرصدةُ وبقي صفُّها موسومًا بسببه'||
      case when v_restore > 0
           then ' · ورُدّ المحسومُ: '||
                v2.ar_count(v_restore,'درجةٌ واحدة','درجتان','درجات','درجة')
           else '' end||
      case when v_forms > 0
           then ' · وسُحبت نماذجُها: '||
                v2.ar_count(v_forms,'نموذجٌ واحد','نموذجان','نماذج','نموذجًا')
           else '' end||
      case when v_told then ' · وأُعلم وليُّ الأمر بالسحب' else '' end||
      ' · وما كسبه الطالبُ من فرص التعويض لا يُستردّ، فالعملُ وقع');
end
$function$
;

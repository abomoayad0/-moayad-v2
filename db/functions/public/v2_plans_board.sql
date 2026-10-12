-- public.v2_plans_board(p_school uuid, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1c1e4a90d7bfd0f0332b8cc0df4e4c77
CREATE OR REPLACE FUNCTION public.v2_plans_board(p_school uuid, p_term smallint DEFAULT NULL::smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_rows jsonb; v_n int; v_wait int; v_appr int; v_nr int; v_short int; v_noowner int;
begin
  perform v2.assert_my_school(p_school,'قراءةَ لوحة التوزيعات');
  perform v2.assert_role(array['principal','deputy','deputy_academic','deputy_school',
    'admin_assistant','info_registrar'],'قراءةَ لوحة التوزيعات');

  select coalesce(jsonb_agg(jsonb_build_object(
      'plan',p.id,'grade',p.grade,'subject_ar',p.subject_ar,'term_no',p.term_no,
      'status',p.status,'source',p.source,'is_locked',p.is_locked,
      'review_path',p.review_path,'without_review',p.approved_without_review,
      'owner', p.owner_person,
      'owner_ar', coalesce((select v2.fn_display_name(pe.full_name)
                             from v2.people pe where pe.id=p.owner_person),'— بلا صاحب'),
      'sections_n',(select count(*) from v2.plan_sections(p.id)),
      'sections_ar',(select string_agg(s.label_ar,' · ' order by s.label_ar)
                      from v2.plan_sections(p.id) s),
      'reviewer', (select v2.fn_display_name(pe.full_name) from v2.people pe where pe.id=p.reviewed_by),
      'assignee', (select v2.fn_display_name(pe.full_name) from v2.people pe where pe.id=p.review_assignee),
      'items',(select count(*) from v2.lesson_plan_items i where i.plan_id=p.id),
      'done',(select count(*) from v2.lesson_plan_items i where i.plan_id=p.id and i.state='done'),
      'done_pairs',(select count(*) from v2.lesson_item_progress pr
                     join v2.lesson_plan_items i2 on i2.id=pr.item_id
                    where i2.plan_id=p.id and pr.voided_at is null and pr.state='done'),
      'merged',(select count(*) from v2.lesson_plan_items i where i.plan_id=p.id and i.merged_into is not null),
      'unplaced',(select count(*) from v2.lesson_plan_items i where i.plan_id=p.id and i.week_no is null),
      'note_ar',p.note_ar,
      'state_ar', case p.status
         when 'draft' then '⚪ مسوّدةٌ لم تُعلن'
         when 'prepared' then '🟠 تنتظر المراجعة'
         when 'reviewed' then '🔵 تنتظر اعتمادَك'
         else case when p.approved_without_review then '🟡 معتمدةٌ بلا مراجعة' else '✅ معتمدة' end end)
      order by p.grade, p.subject_ar, p.term_no,
               (select pe.full_name from v2.people pe where pe.id=p.owner_person)),'[]'::jsonb),
    count(*), count(*) filter (where p.status in ('draft','prepared')),
    count(*) filter (where p.status='approved'),
    count(*) filter (where p.approved_without_review),
    count(*) filter (where (select count(*) from v2.lesson_plan_items i
                             where i.plan_id=p.id and i.week_no is null) > 0),
    count(*) filter (where p.owner_person is null)
    into v_rows, v_n, v_wait, v_appr, v_nr, v_short, v_noowner
    from v2.lesson_plans p
   where p.school_id=p_school and (p_term is null or p.term_no=p_term);

  return jsonb_build_object('rows',v_rows,'count',v_n,
    'waiting',v_wait,'approved',v_appr,'without_review',v_nr,'with_shortfall',v_short,
    'without_owner',v_noowner,
    'summary_ar', case when coalesce(v_n,0)=0
      then 'لا توزيعَ مبنيًّا في مدرستك بعد — ويُحسب لكلّ معلّمٍ في مادّته بزرٍّ واحد'
      else v2.ar_count(v_n,'توزيعٌ واحد','توزيعان','توزيعاتٍ','توزيعًا')
           ||' · معتمدٌ '||v_appr||' · ينتظر '||v_wait
           ||case when v_nr>0 then ' · 🟡 بلا مراجعةٍ '||v_nr else '' end
           ||case when v_short>0 then ' · 🔴 فيه نقصٌ '||v_short else '' end
           ||case when v_noowner>0 then ' · 🔴 بلا صاحبٍ '||v_noowner else '' end end,
    'note_ar','التوزيعُ للمعلّم في مادّته وصفّه ويغطّي فصولَه، والإنجازُ يُرصد لكلّ فصلٍ على حدة. '
      ||'والخطّةُ لا تُعتمد وفيها بندٌ بلا أسبوع. '
      ||'والمعتمدةُ بلا مراجعةٍ تُعرض موسومةً ولا تُخفى. '
      ||'والإقفالُ عند أسبوع الاختبار يمنع التعديلَ ويُبقي الرصد.');
end $function$
;

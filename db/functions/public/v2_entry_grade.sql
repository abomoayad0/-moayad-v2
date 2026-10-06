-- public.v2_entry_grade(p_entry uuid, p_points numeric, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 633647fd6b277a0f4677f964bbc70cad
CREATE OR REPLACE FUNCTION public.v2_entry_grade(p_entry uuid, p_points numeric, p_note text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare x record; o record; m record; sc jsonb; seat text;
        owe numeric; room_pos numeric; room_mer numeric; room_tot numeric;
        comp numeric := 0; mer numeric := 0; left_over numeric;
        msg text; st text; d text; h text; ctx text;
begin
  select * into x from v2.merit_entries where id=p_entry;
  if x.id is null then raise exception 'المشاركةُ غيرُ موجودة'; end if;
  select * into o from v2.merit_opportunities where id=x.opp_id;
  select * into m from v2.conduct_merits where id=o.merit_id;

  seat := v2.my_seat(o.school_id,'guidance');
  if seat is null and v2.my_grant() not in ('owner','admin') then
    raise exception 'تقديرُ الدرجة للجنة التوجيه الطلابيّ — ص١٢ بند ٨'; end if;
  if x.verdict is null then raise exception 'لا تُقدَّر درجةٌ قبل إقرار المشاركة'; end if;
  if x.graded_at is not null then raise exception 'قُدّرت سلفًا'; end if;
  if m.points is null and btrim(coalesce(p_note,''))='' then
    raise exception 'ما لم يُذكر في الجدول يُقدَّر بتوصية اللجنة — فاكتبها'; end if;

  sc := v2.behavior_score(x.student_id, o.year_id, o.term_no);
  owe      := greatest((sc->>'deducted')::numeric - (sc->>'restored')::numeric, 0);
  room_pos := greatest(80 - (sc->>'positive')::numeric, 0);
  room_mer := greatest(20 - (sc->>'merit')::numeric, 0);
  room_tot := greatest(100 - (sc->>'total')::numeric, 0);

  comp := least(p_points, owe, room_pos, room_tot);
  left_over := p_points - comp;
  mer  := least(left_over, room_mer, room_tot - comp);

  if comp > 0 then
    insert into v2.behavior_ledger(school_id,year_id,term_no,student_id,kind,points,
        merit_id,reason,by_person)
    values (o.school_id,o.year_id,o.term_no,x.student_id,'compensation',comp,o.merit_id,
      'تعويضُ '||comp||' درجة · '||m.text_ar||' · '||o.when_ar||
      ' · بتقدير لجنة التوجيه · CONDUCT-1447-OFF '||m.source_page, v2.current_person());
  end if;
  if mer > 0 then
    insert into v2.behavior_ledger(school_id,year_id,term_no,student_id,kind,points,
        merit_id,reason,by_person)
    values (o.school_id,o.year_id,o.term_no,x.student_id,'merit',mer,o.merit_id,
      'اكتسابُ '||mer||' درجة سلوكٍ متميّز · '||m.text_ar||' · '||o.when_ar||
      ' · بتقدير لجنة التوجيه · CONDUCT-1447-OFF '||m.source_page, v2.current_person());
  end if;

  update v2.merit_entries set points=comp+mer, graded_by=v2.current_person(), graded_at=now()
   where id=p_entry;

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
      ref_table,ref_id,visible_to,is_test)
  values (o.school_id,'restore',current_date,x.student_id,
    'قدّرت اللجنةُ '||(comp+mer)||' درجة في '||m.text_ar,
    case when comp>0 and mer>0 then 'تعويضٌ '||comp||' · واكتسابٌ '||mer
         when comp>0 then 'تعويضُ '||comp||' درجة'
         when mer>0  then 'اكتسابُ '||mer||' درجة' else 'لم تُمنح درجة' end,
    'merit_entries',p_entry,'all',coalesce(o.is_test,false));

  return jsonb_build_object('ok',true,'منح',p_points,'تعويض',comp,'اكتساب',mer,
    'مهدور', p_points - comp - mer,
    'الدرجة', v2.behavior_score(x.student_id,o.year_id,o.term_no));
exception when others then
  get stacked diagnostics st=returned_sqlstate, msg=message_text, d=pg_exception_detail,
    h=pg_exception_hint, ctx=pg_exception_context;
  perform v2.fn_log_error(msg,'v2_entry_grade','السلوك المتميز','تقدير درجة',
    jsonb_build_object('entry',p_entry,'points',p_points), st,d,h,ctx,'bridge',
    case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', msg using errcode = st;
end $function$
;

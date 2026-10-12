-- v2.fn_record_practice(p_student uuid, p_code text, p_period smallint, p_subject text, p_note text, p_by uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c9173f473e56afda6ace25f7d9182aef
CREATE OR REPLACE FUNCTION v2.fn_record_practice(p_student uuid, p_code text, p_period smallint DEFAULT NULL::smallint, p_subject text DEFAULT NULL::text, p_note text DEFAULT NULL::text, p_by uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare cp record; sc uuid; y uuid; t smallint; rid uuid; n int; esc uuid := null; k text;
        w numeric; w_max numeric; cap numeric; used numeric; signed numeric; wrote numeric := 0;
        clipped boolean := false; neg_on boolean; loy numeric := 0;
begin
  select * into cp from v2.class_practices where code=p_code and active;
  if cp.code is null then raise exception 'ممارسة غير معروفة: %', p_code; end if;
  select e.school_id, e.year_id into sc, y from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  if sc is null then raise exception 'الطالب لا قيد فعّال له'; end if;
  k := v2.fn_day_kind(sc, current_date);
  if k is null or k not in ('study','exam') then
    raise exception 'اليوم ليس يوم دراسة — نوعه: %', coalesce(k,'غير معروف'); end if;
  t := v2.fn_term_of(sc, current_date);

  if cp.once_per_day and exists (select 1 from v2.practice_records r
      where r.student_id=p_student and r.code=p_code and r.on_date=current_date and r.undone_at is null) then
    raise exception 'هذه الممارسة لا تُرصد أكثر من مرة في اليوم: %', cp.title_ar; end if;

  w       := v2.practice_weight(sc, p_code);
  w_max   := (v2.rule_n(sc,'practice_weight_max_pct'))::numeric / 100;
  cap     := coalesce((select pw.day_cap from v2.practice_weights pw
                        where pw.school_id=sc and pw.code=p_code and pw.active),
                      (v2.rule_n(sc,'practice_day_cap_pct'))::numeric / 100);
  neg_on  := v2.rule_n(sc,'practice_negative_weighed') = 1;

  if w > w_max then
    raise exception 'وزنُ «%» (%) يتجاوز أكبرَ ما يُقبل في الحركة الواحدة (%) — يُضبط في لوحة التحكّم',
      cp.title_ar, v2.ar_num(w), v2.ar_num(w_max);
  end if;

  signed := case when cp.polarity='positive' then w else -1 * w end;

  insert into v2.practice_records(school_id,year_id,term_no,student_id,code,period_no,subject_ar,
    points,note,by_person,by_role)
  values (sc,y,t,p_student,p_code,p_period,p_subject, signed,
    p_note, coalesce(p_by,v2.current_person()), v2.role_ar(v2.my_role()))
  returning id into rid;

  if w > 0 and (cp.polarity='positive' or neg_on) then
    used  := v2.practice_day_used(sc, p_student, current_date);
    wrote := least(w, greatest(cap - used, 0));
    if wrote < w then clipped := true; end if;
    if wrote > 0 then
      insert into v2.practice_points(school_id,year_id,term_no,student_id,points,record_id,reason)
      values (sc,y,t,p_student,
        case when cp.polarity='positive' then wrote else -1 * wrote end,
        rid, cp.title_ar);
    end if;
  end if;

  if cp.polarity = 'positive' then
    loy := v2.loyalty_auto(sc, p_student, 'class_practice',
        coalesce(p_by, v2.current_person()),
        'ممارسةٌ إيجابيّة: '||cp.title_ar, p_period, current_date);
  end if;

  if cp.polarity='negative' and cp.threshold_count is not null then
    select count(*) into n from v2.practice_records r
     where r.student_id=p_student and r.code=p_code and r.undone_at is null
       and (cp.threshold_days is null or r.on_date >= current_date - cp.threshold_days);
    if n >= cp.threshold_count and cp.escalate_to is not null then
      esc := v2.fn_record_behavior(p_student, cp.escalate_to, t, p_period, p_subject,
        'تصعيد آلي: تكرّرت ممارسة «'||cp.title_ar||'» '||n||' مرات'||
        coalesce(' خلال '||cp.threshold_days||' يومًا','')||' — الحدّ '||cp.threshold_count,
        null,false,false,false,false, coalesce(p_by,v2.current_person()));
      update v2.practice_records set escalated_record=esc where id=rid;
    end if;
  end if;

  return jsonb_build_object('record_id',rid,'title',cp.title_ar,'polarity',cp.polarity,
    'period_no', p_period, 'period_ar', v2.period_ar(p_period),
    'weight', w, 'counted', wrote,
    'counted_ar', case
      when w = 0 then 'بلا وزنٍ — عتبةٌ تُحصى ولا تُحسب في الرصيد'
      when cp.polarity='negative' and not neg_on then
        'بلا حسمٍ — السالبُ لا يمسُّ الرصيدَ بقاعدة المدرسة، وهو عتبةٌ تُحصى'
      when clipped then 'بلغ سقفُ اليومِ فحُسب منها '||v2.ar_num(wrote)||' من '||v2.ar_num(w)
      else (case when cp.polarity='positive' then 'أُضيفت ' else 'حُسمت ' end)||v2.ar_num(wrote) end,
    'clipped', clipped, 'day_cap', cap,
    'loyalty_points', loy,
    'loyalty_ar', case when cp.polarity <> 'positive' then null
      when loy > 0 then 'ومعها '||v2.ar_count(loy,'نقطةُ ولاءٍ واحدة','نقطتا ولاء','نقاطِ ولاء','نقطةَ ولاء')
      else 'ولا نقاطَ ولاءٍ — بلغ سقفُها الأسبوعيَّ أو أُغلق مصدرُها' end,
    'count_so_far', n, 'threshold', cp.threshold_count,
    'threshold_ar', v2.practice_threshold_said(p_student, p_code),
    'escalated', esc is not null, 'escalated_record', esc);
end $function$
;

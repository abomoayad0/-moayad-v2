-- public.v2_swap_request(p_my_slot uuid, p_partner_slot uuid, p_on date, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2cdec47b3b2c9a36aa8ea08b35bb1d97
CREATE OR REPLACE FUNCTION public.v2_swap_request(p_my_slot uuid, p_partner_slot uuid, p_on date DEFAULT CURRENT_DATE, p_reason text DEFAULT NULL::text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare
  a record; b record; v_me uuid := v2.current_person(); v_id uuid; v_wd smallint;
  v_ok boolean; v_why text; v_pn text;
begin
  if v_me is null then raise exception 'لا بدّ من تسجيل الدخول'; end if;
  select * into a from v2.timetable where id = p_my_slot;
  select * into b from v2.timetable where id = p_partner_slot;
  if a.id is null or b.id is null then raise exception 'خانةٌ غيرُ موجودة'; end if;
  perform v2.assert_my_school(a.school_id,'طلبَ تبديل حصّة');
  if a.person_id is distinct from v_me then raise exception 'هذي ليست حصّتَك'; end if;
  if b.person_id is null or b.person_id = v_me then raise exception 'لا تُبادل نفسك'; end if;
  if a.school_id <> b.school_id then raise exception 'الحصّتان في مدرستين مختلفتين'; end if;

  v_wd := extract(dow from p_on)::smallint;
  if a.weekday <> v_wd or b.weekday <> v_wd then
    raise exception 'الحصّتان ليستا في يوم % — والتبديلُ في اليوم نفسِه',
      coalesce((select weekday_ar from v2.timetable where weekday=v_wd limit 1), v_wd::text);
  end if;
  if p_on < current_date then raise exception 'ولا تُبدَّل حصّةٌ في يومٍ مضى'; end if;
  if not exists (select 1 from v2.fn_school_days(a.school_id, p_on, p_on)) then
    raise exception 'ليس يومَ دراسةٍ في تقويم مدرستك: %', p_on;
  end if;
  if exists (select 1 from v2.school_weeks(a.school_id) x
              where p_on between x.from_g and x.to_g and x.is_exam) then
    raise exception 'أسبوعُ اختبارٍ — ولا تبديلَ فيه';
  end if;

  -- 🔒 الحصّةُ تُبدَّل مرّةً واحدةً في اليوم
  if exists (select 1 from v2.period_swaps w
              where w.school_id=a.school_id and w.on_date=p_on
                and w.status in ('pending','partner_ok','done')
                and (w.req_slot in (p_my_slot,p_partner_slot)
                  or w.partner_slot in (p_my_slot,p_partner_slot))) then
    raise exception 'إحدى الحصّتين مبدَّلةٌ أو مطلوبةٌ ذلك اليوم — والحصّةُ تُبدَّل مرّةً واحدة';
  end if;

  -- 🔒 ولا تُبدَّل حصّةٌ مضت اليوم
  if p_on = current_date and exists (
       select 1 from v2.period_slots s
        where s.school_id=a.school_id and s.period_no in (a.period_no, b.period_no)
          and s.ends_at < (now() at time zone 'Asia/Riyadh')::time) then
    raise exception 'إحدى الحصّتين انتهت — ولا تُبدَّل حصّةٌ مضت';
  end if;

  -- 🔒 ويُقرأ المانعُ من المرشّحين أنفسِهم فلا يتعدّد الحكم
  select m.ok, m.why_ar into v_ok, v_why
    from v2.swap_matches(p_my_slot, p_on) m where m.slot = p_partner_slot;
  if v_ok is null then raise exception 'هذي الحصّةُ ليست من مرشّحي التبديل لحصّتك'; end if;
  if not v_ok then raise exception '%', v_why; end if;

  insert into v2.period_swaps(school_id,on_date,requester,req_slot,partner,partner_slot,reason_ar)
  values (a.school_id,p_on,v_me,p_my_slot,b.person_id,p_partner_slot,
          nullif(btrim(coalesce(p_reason,'')),''))
  returning id into v_id;

  select v2.fn_display_name(full_name) into v_pn from v2.people where id=b.person_id;
  perform v2.swap_notify(a.school_id,'طلبُ تبديل حصّة',
    (select v2.fn_display_name(full_name) from v2.people where id=v_me)
      || ' يطلب تبديلَ الحصّة ' || v2.ar_num(a.period_no) || ' بحصّتك ' || v2.ar_num(b.period_no),
    b.person_id, p_on);

  return 'أُرسل الطلبُ إلى ' || v_pn || ' — ينتظر موافقتَه ثمّ اعتمادَ الوكيل للشؤون التعليميّة';
end $function$
;

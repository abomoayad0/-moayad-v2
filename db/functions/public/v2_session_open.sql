-- public.v2_session_open(p_period smallint, p_section uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 0eebcc338fb380d4f47719b0fa09dd46
CREATE OR REPLACE FUNCTION public.v2_session_open(p_period smallint, p_section uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid := v2.acting_school(); me uuid := v2.current_person(); sid uuid; s record;
begin
  if me is null then raise exception 'لا بدّ من تسجيل الدخول'; end if;
  if sc is null then raise exception 'أيُّ مدرسة؟'; end if;
  perform v2.session_autoclose(sc);

  sid := v2.session_of(sc, me, current_date, p_period, p_section, true);
  if sid is null then raise exception 'الحصّةُ % ليست حصّتَك اليومَ', v2.ar_num(p_period); end if;
  select * into s from v2.class_sessions where id = sid;
  if s.closed_at is not null then
    raise exception 'أُقفلت هذي الحصّةُ — %', coalesce(s.note_ar,'وانقضت نافذتُها');
  end if;
  return jsonb_build_object('ok',true,'session',sid,
    'period',s.period_no,'subject',s.subject_ar,
    'basis_ar', case s.basis when 'swap' then 'بتبديلٍ من '||coalesce(s.from_ar,'زميل')
                             when 'cover' then 'تغطيةً عن '||coalesce(s.from_ar,'زميل')
                             else 'أصالةً' end,
    'late_min', s.late_min,
    'msg', 'فُتحت الحصّةُ '||v2.ar_num(s.period_no)||
      case when coalesce(s.late_min,0) > (v2.rule_n(sc,'session_late_open_min'))::int
           then ' — بعد '||v2.ar_num(s.late_min)||' دقيقة من بدئها' else '' end);
end $function$
;

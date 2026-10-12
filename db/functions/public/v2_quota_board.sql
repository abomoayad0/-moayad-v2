-- public.v2_quota_board(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c1527f4866ee0812a330cc84dfdc93f8
CREATE OR REPLACE FUNCTION public.v2_quota_board(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if not v2.my_school(p_school) then raise exception '%', v2.not_my_school_ar(); end if;
  select jsonb_build_object(
    'quota', (select coalesce(jsonb_agg(jsonb_build_object(
          'post',q.post_key,'post_ar',v2.role_ar(q.post_key),
          'min',q.min_slots,'min_ar',v2.ar_num(q.min_slots),
          'max',q.max_slots,'max_ar',v2.ar_num(q.max_slots),
          'standby_max',q.standby_max,
          'standby_max_ar', case when q.standby_max is null then 'بلا حدٍّ مضبوط'
                                 else v2.ar_count(q.standby_max,'حصّةُ انتظارٍ واحدة','حصّتا انتظار','حصصِ انتظار','حصّةَ انتظار') end,
          'said_ar', coalesce(v2.role_ar(q.post_key), q.post_key)||' — من '||
                     v2.ar_num(q.min_slots)||' إلى '||
                     v2.ar_count(q.max_slots,'حصّةٍ واحدة','حصّتين','حصص','حصّة'),
          'note',q.note_ar)
          order by q.max_slots desc),'[]'::jsonb)
        from v2.teaching_quota q where q.school_id=p_school),
    'plan', (select coalesce(jsonb_agg(jsonb_build_object(
          'id',s.id,'grade',s.grade,'grade_ar',v2.grade_ar(s.grade),
          'subject',s.subject_ar,'slots',s.slots,
          'slots_ar',v2.ar_count(s.slots,'حصّةٌ واحدة','حصّتان','حصص','حصّة'),
          'said_ar', s.subject_ar||' — '||v2.grade_ar(s.grade)||' — '||
                     v2.ar_count(s.slots,'حصّةٌ واحدة','حصّتان','حصص','حصّة')||' في الأسبوع',
          'ord',s.ord) order by s.grade, s.ord, s.subject_ar),'[]'::jsonb)
        from v2.subject_plan s where s.school_id=p_school and s.active),
    'teachers', (select coalesce(jsonb_agg(jsonb_build_object(
          'person_id',x.pid,'person',x.nm,'post',x.post,'subjects',x.subs,
          'now_teaching',x.te,'now_standby',x.sb,'quota_max',x.qmax,
          'now_teaching_ar', v2.ar_count0(x.te,'لا تدريسَ له','حصّةُ تدريسٍ واحدة','حصّتا تدريس','حصصِ تدريس','حصّةَ تدريس'),
          'now_standby_ar',  v2.ar_count0(x.sb,'لا انتظارَ عليه','حصّةُ انتظارٍ واحدة','حصّتا انتظار','حصصِ انتظار','حصّةَ انتظار'),
          'quota_max_ar', case when x.qmax is null then 'لا نصابَ مضبوطٌ لتكليفه'
                               else 'نصابُه '||v2.ar_count(x.qmax,'حصّةٌ واحدة','حصّتان','حصص','حصّة') end,
          'load_ar', 'تدريسٌ '||v2.ar_num(x.te)||' · وانتظارٌ '||v2.ar_num(x.sb)||
                     case when x.qmax is null then ' · ولا نصابَ مضبوطٌ لتكليفه'
                          else ' · ونصابُه '||v2.ar_num(x.qmax) end,
          'over_ar', case when x.qmax is null then null
                          when x.te > x.qmax then 'فوق نصابه بـ'||
                               v2.ar_count(x.te - x.qmax,'حصّةٍ واحدة','حصّتين','حصص','حصّة')
                          when x.te = x.qmax then 'بلغ نصابَه'
                          else 'وبقي له '||v2.ar_count(x.qmax - x.te,'حصّةٌ واحدة','حصّتان','حصص','حصّة') end)
          order by x.nm),'[]'::jsonb)
        from (
          select pe.id pid, v2.fn_display_name(pe.full_name) nm,
            (select string_agg(distinct a.post_key,',') from v2.assignments a
              where a.person_id=pe.id and a.school_id=p_school and a.ended_on is null) post,
            (select coalesce(jsonb_agg(jsonb_build_object(
                  'subject',ts.subject_ar,'main',ts.is_main)),'[]'::jsonb)
               from v2.teacher_subjects ts
              where ts.school_id=p_school and ts.person_id=pe.id) subs,
            (select count(*)::int from v2.timetable t
              where t.school_id=p_school and t.person_id=pe.id and t.slot_kind='teaching') te,
            (select count(*)::int from v2.timetable t
              where t.school_id=p_school and t.person_id=pe.id and t.slot_kind='standby') sb,
            (select max(q.max_slots) from v2.teaching_quota q
               join v2.assignments a on a.post_key=q.post_key
              where q.school_id=p_school and a.person_id=pe.id
                and a.school_id=p_school and a.ended_on is null) qmax
          from v2.people pe
          where exists (select 1 from v2.assignments a
                         where a.person_id=pe.id and a.school_id=p_school and a.ended_on is null)
        ) x),
    'balance', (select jsonb_build_object(
          'planned', b.pl, 'scheduled', b.sc,
          'planned_ar', v2.ar_count0(b.pl,'لا خطّةَ مضبوطة','حصّةٌ واحدة','حصّتان','حصص','حصّة'),
          'scheduled_ar', v2.ar_count0(b.sc,'لم يُجدول شيءٌ بعد','حصّةٌ واحدة','حصّتان','حصص','حصّة'),
          'gap', b.pl - b.sc,
          'said_ar', 'المنهجُ يطلب '||v2.ar_num(b.pl)||' حصّةً في الأسبوع · والمجدولُ '||v2.ar_num(b.sc)||
            case when b.pl = b.sc then ' · فالميزانُ تامّ'
                 when b.pl > b.sc then ' · فالناقصُ '||v2.ar_count(b.pl-b.sc,'حصّةٌ واحدة','حصّتان','حصص','حصّة')
                 else ' · والزائدُ '||v2.ar_count(b.sc-b.pl,'حصّةٌ واحدة','حصّتان','حصص','حصّة') end)
        from (select
                (select coalesce(sum(s.slots * (select count(*) from v2.class_sections c
                     where c.school_id=p_school and c.grade=s.grade and c.active)),0)::int
                   from v2.subject_plan s where s.school_id=p_school and s.active) pl,
                (select count(*)::int from v2.timetable t
                   where t.school_id=p_school and t.slot_kind='teaching') sc) b)
  ) into r;
  return r;
end $function$
;

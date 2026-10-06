-- public.v2_slot_save(p_school uuid, p_slot uuid, p_weekday smallint, p_period smallint, p_section uuid, p_person uuid, p_kind text, p_subject text, p_room text, p_note text, p_force boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5a941b121aacc8bfe120baa018580310
CREATE OR REPLACE FUNCTION public.v2_slot_save(p_school uuid, p_slot uuid, p_weekday smallint, p_period smallint, p_section uuid, p_person uuid, p_kind text, p_subject text, p_room text, p_note text, p_force boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare nid uuid; chk jsonb; yid uuid; tm smallint; wd text;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic'],
                         'ضبطَ جدول الحصص');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if p_weekday is null or p_weekday not between 1 and 5 then
    raise exception 'اليوم: الأحدُ إلى الخميس'; end if;
  if p_period is null then raise exception 'اختر الحصّة'; end if;
  if not exists (select 1 from v2.period_slots s
                  where s.school_id=p_school and s.period_no=p_period) then
    raise exception 'الحصّةُ % ليست في حصص مدرستك', v2.ar_num(p_period); end if;
  if coalesce(p_kind,'teaching') not in ('teaching','standby','activity') then
    raise exception 'نوعُ الحصّة: تدريسٌ أو انتظارٌ أو نشاط'; end if;
  if coalesce(p_kind,'teaching')='teaching' and p_section is null then
    raise exception 'حصّةُ التدريس يلزمها فصل'; end if;
  if p_person is not null and not exists (select 1 from v2.assignments a
        where a.person_id=p_person and a.school_id=p_school and a.ended_on is null) then
    raise exception 'هذا المنسوب ليس من منسوبي مدرستك'; end if;
  if p_section is not null and not exists (select 1 from v2.class_sections c
        where c.id=p_section and c.school_id=p_school) then
    raise exception 'هذا الفصلُ ليس من فصول مدرستك'; end if;

  -- 🔑 التضاربُ يُعرض ولا يُتجاوز إلا بإقرارٍ صريح
  chk := public.v2_slot_check(p_school,p_slot,p_weekday,p_period,p_section,p_person,p_kind);
  if not (chk->>'ok')::boolean and not coalesce(p_force,false) then
    raise exception '%', (select string_agg(x->>'text',' · ')
                            from jsonb_array_elements(chk->'conflicts') x);
  end if;

  wd := (array['الأحد','الاثنين','الثلاثاء','الأربعاء','الخميس'])[p_weekday];
  select e.year_id into yid from v2.enrolments e
   where e.school_id=p_school and e.status='active' limit 1;
  tm := coalesce(v2.term_of_strict(p_school,current_date),1);

  if p_slot is null then
    insert into v2.timetable(school_id,year_id,term_no,weekday,weekday_ar,period_no,
        section_id,person_id,subject_ar,room_ar,note,slot_kind,is_activity)
    values (p_school,yid,tm,p_weekday,wd,p_period,p_section,p_person,
        nullif(btrim(coalesce(p_subject,'')),''),nullif(btrim(coalesce(p_room,'')),''),
        nullif(btrim(coalesce(p_note,'')),''),coalesce(p_kind,'teaching'),
        (coalesce(p_kind,'teaching')='activity'))
    returning id into nid;
    return jsonb_build_object('ok',true,'slot',nid,'mode','أُضيفت',
      'forced', coalesce(p_force,false) and not (chk->>'ok')::boolean);
  end if;

  if not exists (select 1 from v2.timetable where id=p_slot and school_id=p_school) then
    raise exception 'هذي الحصّةُ ليست في جدول مدرستك'; end if;
  update v2.timetable set
    weekday=p_weekday, weekday_ar=wd, period_no=p_period,
    section_id=p_section, person_id=p_person,
    subject_ar=nullif(btrim(coalesce(p_subject,'')),''),
    room_ar=nullif(btrim(coalesce(p_room,'')),''),
    note=nullif(btrim(coalesce(p_note,'')),''),
    slot_kind=coalesce(p_kind,slot_kind),
    is_activity=(coalesce(p_kind,slot_kind)='activity')
   where id=p_slot;
  return jsonb_build_object('ok',true,'slot',p_slot,'mode','عُدّلت',
    'forced', coalesce(p_force,false) and not (chk->>'ok')::boolean);
end $function$
;

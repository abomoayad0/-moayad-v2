-- v2.card_blocked(p_student uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 89918d9f63dc58fe4893ce9b44fa994d
CREATE OR REPLACE FUNCTION v2.card_blocked(p_student uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare a record; p record; sc uuid; v_any int; v_per int;
begin
  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  if sc is null then return 'الطالبُ لا قيدَ فعّالَ له'; end if;
  v_any := v2.rule_n(sc,'card_blocked_any_period');

  select * into a from v2.attendance
   where student_id=p_student and on_date=p_date limit 1;
  if a.id is not null and a.state='absent' then
    return case when a.permit_id is not null
      then 'الطالبُ غائبٌ بعذرٍ اليومَ — ولا يُرصد عليه شيء'
      else 'الطالبُ مرصودٌ غائبًا اليومَ — ولا يُرصد عليه شيء' end;
  end if;

  -- غائبٌ في حصّةٍ من اليوم — بمفتاح لوحة التحكّم
  if v_any = 1 then
    select count(*) into v_per from v2.period_attendance pa
     where pa.student_id=p_student and pa.on_date=p_date and pa.state='absent';
    if v_per > 0 then
      return 'الطالبُ مرصودٌ غائبًا في حصّةٍ من هذا اليوم — ولا يُرصد عليه شيء (مفتاحٌ في لوحة التحكّم)';
    end if;
  end if;

  select * into p from v2.student_permissions
   where student_id=p_student and on_date=p_date
     and out_at is not null and coalesce(returned,false)=false
   order by out_at desc limit 1;
  if p.id is not null then
    return 'الطالبُ انصرف اليومَ — ولا يُرصد عليه شيء';
  end if;

  return null;
end $function$
;

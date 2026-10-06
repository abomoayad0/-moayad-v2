-- v2.g_attendee_identity()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c219f7445644258ba1c9416c5b1dfc80
CREATE OR REPLACE FUNCTION v2.g_attendee_identity()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  if new.invited_as = 'مستدعى' then
    new.can_vote := false; new.seat_role := null;
    if coalesce(new.guest_kind,'منسوب') <> 'منسوب' then
      if new.person_id is not null then
        raise exception 'المستدعى من غير المنسوبين لا يُربط بسجلّ منسوب';
      end if;
      if new.guest_kind='طالب' and new.guest_student_id is null then
        raise exception 'اختر الطالبَ المستدعى';
      end if;
      if new.guest_kind='وليّ أمر' and new.guest_guardian_id is null then
        raise exception 'اختر وليَّ الأمر المستدعى';
      end if;
      -- الاسمُ يُقرأ من مصدره لا يُكتب باليد
      if new.guest_kind='طالب' then
        select full_name into new.guest_name from v2.students where id=new.guest_student_id;
      else
        select full_name into new.guest_name from v2.guardians where id=new.guest_guardian_id;
      end if;
    end if;
  else
    if new.person_id is null then raise exception 'عضوُ اللجنة يُربط بسجلّ منسوب'; end if;
    new.guest_kind := 'منسوب';
  end if;
  return new;
end $function$
;

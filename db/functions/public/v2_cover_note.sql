-- public.v2_cover_note(p_cover uuid, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f0d7c6a113f303be3c314d7d66f55b00
CREATE OR REPLACE FUNCTION public.v2_cover_note(p_cover uuid, p_note text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare c v2.period_covers;
begin
  select * into c from v2.period_covers where id = p_cover and voided_at is null;
  if c.id is null then raise exception 'لا سجلَّ تغطيةٍ بهذا الرقم'; end if;
  perform v2.assert_my_school(c.school_id, 'كتابة ما صُنع في الحصّة');
  if c.cover_person is distinct from v2.current_person() then
    perform v2.assert_role(array['principal','deputy_academic','deputy','deputy_school'],
                           'كتابة ما صُنع في حصّة غيرك');
  end if;
  update v2.period_covers set invest_note_ar = nullif(btrim(p_note),'') where id = p_cover;
  return 'حُفظ · واستثمارُ حصص الانتظار منصوصٌ في «رفق» ص١٩';
end $function$
;

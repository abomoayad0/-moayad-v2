-- public.v2_census_review(p_census uuid, p_accept boolean, p_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2f8b9a35d24fd60c80b5d6313a0470ad
CREATE OR REPLACE FUNCTION public.v2_census_review(p_census uuid, p_accept boolean, p_why text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare c record; closed boolean := false;
begin
  perform v2.assert_role(array['deputy_students','deputy','principal'],'النظرَ في الحصر');
  select * into c from v2.behavior_census where id=p_census;
  if c.id is null then raise exception 'تكليفُ الحصر غيرُ موجود'; end if;
  if not v2.my_school(c.school_id) then raise exception 'ليست مدرستك'; end if;
  if c.state <> 'مكتمل' then raise exception 'لم يُسلَّم هذا الحصرُ بعد'; end if;

  if coalesce(p_accept,false) then
    if c.task_id is not null then
      update v2.behavior_tasks set status='done', done_at=now(),
          done_by=v2.current_person(),
          ev_on=coalesce(ev_on,current_date),
          ev_text='حُصرت السلوكيّاتُ وسُلّمت وقُبلت'
       where id=c.task_id and status<>'done';
      closed := found;
    end if;
    return jsonb_build_object('ok',true,'closed',closed,
      'note', case when closed then 'قُبل الحصرُ وأُقفلت المهمّة' else 'قُبل الحصر' end);
  end if;
  if btrim(coalesce(p_why,''))='' then
    raise exception 'لا يُردّ حصرٌ بلا سببٍ مكتوب'; end if;
  update v2.behavior_census set state='مُعاد', returned_why=btrim(p_why),
      filed_at=null where id=p_census;
  return jsonb_build_object('ok',true,'note','أُعيد الحصرُ لصاحبه بسببه');
end $function$
;

-- public.v2_opp_open(p_school uuid, p_merit integer, p_kind text, p_title text, p_when text, p_capacity smallint, p_held_by uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6b0a732f1f184e371d49d202f4dced34
CREATE OR REPLACE FUNCTION public.v2_opp_open(p_school uuid, p_merit integer, p_kind text, p_title text, p_when text, p_capacity smallint, p_held_by uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare seat text; nid uuid; m record;
begin
  seat := v2.my_seat(p_school,'guidance');
  if seat is null and (v2.my_grant() is null or v2.my_grant() not in ('owner','admin')) then
    raise exception 'فتحُ فرص التعويض للجنة التوجيه الطلابيّ — ص١٢ بند ١٠'; end if;
  select * into m from v2.conduct_merits where id=p_merit;
  if m.id is null then raise exception 'ممارسةٌ غيرُ معروفة'; end if;
  if btrim(coalesce(p_when,''))='' then raise exception 'لا فرصةَ بلا موعدٍ ومكان'; end if;
  if p_capacity is not null and p_capacity < 1 then raise exception 'السعةُ واحدٌ فأكثر'; end if;

  insert into v2.merit_opportunities(school_id,merit_id,kind,title_ar,when_ar,capacity,
      held_by,opened_by,year_id,term_no,is_test)
  select p_school,p_merit,coalesce(p_kind,'منظَّمة'),nullif(btrim(coalesce(p_title,'')),''),
      btrim(p_when),p_capacity,p_held_by,v2.current_person(),
      e.year_id, v2.fn_term_of(p_school,current_date),
      coalesce((select test_mode from v2.schools where id=p_school),false)
  from v2.enrolments e where e.school_id=p_school and e.status='active' limit 1
  returning id into nid;
  return jsonb_build_object('ok',true,'opp',nid,'merit',m.text_ar,'points',m.points);
end $function$
;

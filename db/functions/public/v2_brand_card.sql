-- public.v2_brand_card(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 bb43afe578fbdb05e037773785009555
CREATE OR REPLACE FUNCTION public.v2_brand_card(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select jsonb_build_object(
    'brand', coalesce((select to_jsonb(b) from v2.branding b where b.school_id=p_school),'{}'::jsonb),
    'stamp', (select jsonb_build_object('id',st.id,'image',st.image_ref,
                'from',st.valid_from,'to',st.valid_to)
              from v2.stamps st where st.school_id=p_school
                and st.valid_from <= current_date
                and (st.valid_to is null or st.valid_to >= current_date)
              order by st.valid_from desc limit 1),
    'stamp_next', (select jsonb_build_object('id',st.id,'image',st.image_ref,'from',st.valid_from)
              from v2.stamps st where st.school_id=p_school and st.valid_from > current_date
              order by st.valid_from limit 1),
    'stamps_past', (select coalesce(jsonb_agg(jsonb_build_object(
                'id',st.id,'image',st.image_ref,'from',st.valid_from,'to',st.valid_to)
                order by st.valid_to desc),'[]'::jsonb)
              from v2.stamps st where st.school_id=p_school
                and st.valid_to is not null and st.valid_to < current_date),
    'signatures', (select coalesce(jsonb_agg(jsonb_build_object(
          'id',sg.id,'person',pe.id,'name',v2.fn_display_name(pe.full_name),
          'image',sg.image_ref,'from',sg.valid_from,'to',sg.valid_to)),'[]'::jsonb)
        from v2.signatures sg join v2.people pe on pe.id=sg.person_id
        where exists (select 1 from v2.assignments a
                       where a.person_id=pe.id and a.school_id=p_school and a.ended_on is null)
          and sg.valid_from <= current_date
          and (sg.valid_to is null or sg.valid_to >= current_date)),
    'signatures_past', (select coalesce(jsonb_agg(jsonb_build_object(
          'id',sg.id,'name',v2.fn_display_name(pe.full_name),
          'image',sg.image_ref,'from',sg.valid_from,'to',sg.valid_to)
          order by sg.valid_to desc),'[]'::jsonb)
        from v2.signatures sg join v2.people pe on pe.id=sg.person_id
        where exists (select 1 from v2.assignments a
                       where a.person_id=pe.id and a.school_id=p_school and a.ended_on is null)
          and sg.valid_to is not null and sg.valid_to < current_date),
    'note','الشعارُ والختمُ والتوقيعُ تظهر في كلّ نموذجٍ يُطبع — والسابقُ لا يُمحى'
  ) into r;
  return r;
end $function$
;

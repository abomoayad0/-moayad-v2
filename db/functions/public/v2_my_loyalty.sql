-- public.v2_my_loyalty()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5f2454ac4946ff73a68392c971380aca
CREATE OR REPLACE FUNCTION public.v2_my_loyalty()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_st uuid; sc uuid; bal int;
begin
  select s.id, s.school_id into v_st, sc from v2.students s
   where s.user_id = auth.uid() and coalesce(s.portal_active, false);
  if v_st is null then raise exception 'بوّابتُك غيرُ مفتوحة'; end if;
  bal := v2.loyalty_balance(sc, v_st);
  return jsonb_build_object(
    'balance', bal,
    'balance_ar', v2.ar_count(bal, 'نقطةٌ واحدة', 'نقطتان', 'نقاط', 'نقطة'),
    'moves', coalesce((
       select jsonb_agg(jsonb_build_object(
           'kind', m.kind, 'points', m.points,
           'title_ar', coalesce(
              (select title_ar from v2.loyalty_sources s
                where s.code=m.source_code and (s.school_id=sc or s.school_id is null)
                order by (s.school_id is null) limit 1),
              (select title_ar from v2.loyalty_rewards w
                where w.code=m.reward_code and (w.school_id=sc or w.school_id is null)
                order by (w.school_id is null) limit 1),
              'حركة'),
           'on_ar', v2.fn_to_hijri(m.on_date),
           'by_role_ar', m.by_role_ar)
         order by m.created_at desc)
       from (select * from v2.loyalty_ledger
              where student_id = v_st and voided_at is null
              order by created_at desc limit 30) m), '[]'::jsonb),
    'rewards', coalesce((
       select jsonb_agg(jsonb_build_object(
           'title_ar', z.title_ar, 'price', z.price,
           'afford', z.price <= bal,
           'short_by', greatest(z.price - bal, 0),
           'needs_principal', z.needs_principal,
           'who_ar', (select string_agg(coalesce(v2.role_ar(r), r), ' أو ') from unnest(z.who_may_spend) r),
           'note_ar', z.note_ar) order by z.price)
       from (select distinct on (code) * from v2.loyalty_rewards
              where active and (school_id = sc or school_id is null)
              order by code, (school_id is null)) z), '[]'::jsonb),
    'how_ar', 'النقاطُ تُكتسب من انضباطك ومشاركتك وحضورك ومن برامج المدرسة — ولا يمنحها إلّا من كُلِّف بها.');
end $function$
;

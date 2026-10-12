-- public.v2_loyalty_wallet(p_student uuid, p_limit integer)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7333f7bf267e41fdbac85226cc503c3f
CREATE OR REPLACE FUNCTION public.v2_loyalty_wallet(p_student uuid, p_limit integer DEFAULT 20)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; bal int; v_earn int; v_ded int; v_spend int;
begin
  perform v2.assert_my_student(p_student, 'قراءةَ محفظة نقاطه');
  select school_id into sc from v2.students where id = p_student;
  bal := v2.loyalty_balance(sc, p_student);
  select coalesce(sum(case when kind='earn' then points end),0),
         coalesce(sum(case when kind='deduct' then points end),0),
         coalesce(sum(case when kind='spend' then points end),0)
    into v_earn, v_ded, v_spend
    from v2.loyalty_ledger where student_id=p_student and voided_at is null;

  return jsonb_build_object(
    'student', (select v2.fn_display_name(full_name) from v2.students where id = p_student),
    'balance', bal,
    'balance_ar', v2.ar_balance(bal),
    'earned', v_earn, 'deducted', v_ded, 'spent', v_spend,
    'totals_ar', concat_ws(' · ',
      'كسبَ '||v2.ar_count0(v_earn,'لا شيء','نقطةً واحدة','نقطتين','نقاط','نقطة'),
      'وخُصمت منه '||v2.ar_count0(v_ded,'لا شيء','نقطةٌ واحدة','نقطتان','نقاط','نقطة'),
      'وصرفَ '||v2.ar_count0(v_spend,'لا شيء','نقطةً واحدة','نقطتين','نقاط','نقطة')),
    'moves', coalesce((
       select jsonb_agg(jsonb_build_object(
           'id', m.id, 'kind', m.kind, 'points', m.points,
           'points_ar', case m.kind
               when 'earn'   then '+'||v2.ar_count(m.points,'نقطةٌ واحدة','نقطتان','نقاط','نقطة')
               when 'deduct' then '−'||v2.ar_count(m.points,'نقطةٌ واحدة','نقطتان','نقاط','نقطة')
               else 'صُرفت '||v2.ar_count(m.points,'نقطةٌ واحدة','نقطتان','نقاط','نقطة') end,
           'title_ar', coalesce(
              (select title_ar from v2.loyalty_sources s
                where s.code=m.source_code and (s.school_id=m.school_id or s.school_id is null)
                order by (s.school_id is null) limit 1),
              (select title_ar from v2.loyalty_rewards w
                where w.code=m.reward_code and (w.school_id=m.school_id or w.school_id is null)
                order by (w.school_id is null) limit 1),
              'حركةٌ بلا مصدر'),
           'reason_ar', m.reason_ar,
           'on_ar', v2.fn_to_hijri(m.on_date),
           'period_no', m.period_no,
           'period_ar', v2.period_ar(m.period_no),
           'by_ar', (select v2.fn_display_name(p.full_name) from v2.people p where p.id=m.by_person),
           'by_role_ar', m.by_role_ar,
           'can_undo', m.by_person = v2.current_person()
                       and extract(epoch from (now()-m.created_at))/60
                           <= v2.rule_n(m.school_id,'loyalty_undo_minutes'))
         order by m.created_at desc)
       from (select * from v2.loyalty_ledger
              where student_id = p_student and voided_at is null
              order by created_at desc limit greatest(p_limit,1)) m), '[]'::jsonb),
    'can_afford', coalesce((
       select jsonb_agg(jsonb_build_object('code', z.code, 'title_ar', z.title_ar,
           'price', z.price,
           'price_ar', 'بـ'||v2.ar_count(z.price,'نقطةٍ واحدة','نقطتين','نقاط','نقطة'))
                order by z.price)
       from (select distinct on (code) * from v2.loyalty_rewards
              where active and (school_id = sc or school_id is null)
              order by code, (school_id is null)) z
       where z.price <= bal and v2.loyalty_can(z.who_may_spend)), '[]'::jsonb));
end $function$
;

-- public.v2_terms_from_calendar(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 22b06fc82bd3d200d201e1043330c1e7
CREATE OR REPLACE FUNCTION public.v2_terms_from_calendar(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_scope text; v_cyear uuid; v_refyear uuid; v_made int := 0; v_rows jsonb := '[]'::jsonb; r record;
begin
  perform v2.assert_my_school(p_school,'توليدَ فصول السنة');
  perform v2.assert_role(array['principal','deputy','deputy_school','deputy_academic',
    'deputy_school_students','admin_assistant','admin_assistant_students','info_registrar'],
    'توليدَ فصول السنة');

  select s.calendar_scope into v_scope from v2.schools s where s.id=p_school;
  if v_scope is null then
    raise exception 'مسارُ التقويم غيرُ محدَّدٍ لمدرستك — فحدِّده أوّلًا ثمّ تُولَّد الفصول';
  end if;

  select y.id into v_cyear from v2.academic_years y where y.school_id=p_school and y.is_current limit 1;
  if v_cyear is null then
    raise exception 'لا سنةَ دراسيّةٌ حاليّةٌ لمدرستك — ولا تُولَّد فصولٌ بلا سنة';
  end if;

  select cy.id into v_refyear from v2.calendar_years cy where cy.scope_key=v_scope limit 1;
  if v_refyear is null or not exists (select 1 from v2.calendar_weeks where year_id=v_refyear) then
    raise exception 'لا أسابيعَ منزَّلةٌ لمسارك — فلا يُولَّد منه فصل';
  end if;

  for r in
    select w.term_no, min(w.from_g) f, max(w.to_g) t, count(*) n
      from v2.calendar_weeks w where w.year_id=v_refyear and w.from_g is not null
     group by w.term_no order by w.term_no
  loop
    if exists (select 1 from v2.terms x where x.year_id=v_cyear and x.number=r.term_no) then
      update v2.terms set starts_on = coalesce(starts_on, r.f), ends_on = coalesce(ends_on, r.t)
       where year_id=v_cyear and number=r.term_no;
      v_rows := v_rows || jsonb_build_object('term_no',r.term_no,'state','موجودٌ — لم يُنشأ');
    else
      insert into v2.terms (id, year_id, number, starts_on, ends_on, is_current)
      values (gen_random_uuid(), v_cyear, r.term_no, r.f, r.t,
              (current_date between r.f and r.t));
      v_made := v_made + 1;
      v_rows := v_rows || jsonb_build_object('term_no',r.term_no,
        'from_h',v2.fn_to_hijri(r.f),'to_h',v2.fn_to_hijri(r.t),
        'weeks_n',r.n,'state','أُنشئ');
    end if;
  end loop;

  return jsonb_build_object('ok',true,'made',v_made,'rows',v_rows,
    'summary_ar', case when v_made=0 then 'فصولُ سنتك مُسجَّلةٌ من قبل — ولم يُنشأ شيء'
      else v2.ar_count(v_made,'أُنشئ فصلٌ واحد','أُنشئ فصلان','فصولٍ أُنشئت','فصلًا أُنشئ')
           ||' من تقويم مسارك' end,
    'note_ar','وتواريخُ الفصلِ مأخوذةٌ من أوّلِ أسبوعٍ إلى آخرِه في تقويم مسارك — فإن أردتَ غيرَها فعدِّلها بيدك.');
end $function$
;

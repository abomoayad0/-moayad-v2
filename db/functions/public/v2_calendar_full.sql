-- public.v2_calendar_full(p_school uuid, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e3cbe88b9e007fd0fab01270426bd985
CREATE OR REPLACE FUNCTION public.v2_calendar_full(p_school uuid, p_term smallint DEFAULT NULL::smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare
  v_scope text; v_cyear uuid; v_refyear uuid; v_terms int; v_checks jsonb := '[]'::jsonb;
  v_weeks int; v_noweeks int; v_cust int; v_r jsonb;
begin
  perform v2.assert_my_school(p_school, 'قراءةَ التقويم');

  select s.calendar_scope into v_scope from v2.schools s where s.id=p_school;
  select y.id into v_cyear from v2.academic_years y
   where y.school_id=p_school and y.is_current limit 1;
  select cy.id into v_refyear from v2.calendar_years cy where cy.scope_key = v_scope limit 1;
  select count(*) into v_terms from v2.terms t where t.year_id = v_cyear;

  select count(*), count(*) filter (where w.from_g is null or w.to_g is null),
         count(*) filter (where w.is_custom)
    into v_weeks, v_noweeks, v_cust
    from v2.school_weeks(p_school) w;

  -- ═══ الفحوصُ ═══
  if v_scope is null then
    v_checks := v_checks || jsonb_build_object('level','🔴',
      'text_ar','مسارُ التقويم غيرُ محدَّدٍ لمدرستك — ولا تُعرف أسابيعُها حتى يُحدَّد',
      'fix','v2_calendar_scope_set');
  elsif coalesce(v_weeks,0) = 0 then
    v_checks := v_checks || jsonb_build_object('level','🔴',
      'text_ar','مسارُك «'||coalesce((select label_ar from v2.calendar_scopes where key=v_scope),v_scope)
                ||'» لا أسابيعَ منزَّلةٌ له — فاختر مسارًا فيه أسابيعُ السنة',
      'fix','v2_calendar_scope_set');
  end if;

  if v_cyear is null then
    v_checks := v_checks || jsonb_build_object('level','🔴',
      'text_ar','لا سنةَ دراسيّةٌ حاليّةٌ لمدرستك — ولا يُبنى تقويمٌ بلا سنة','fix',null);
  elsif v_terms = 0 then
    v_checks := v_checks || jsonb_build_object('level','🟠',
      'text_ar','سنتُك الحاليّةُ بلا فصولٍ مُسجَّلة — ويُولَّدان من تقويم مسارك بزرٍّ واحد',
      'fix','v2_terms_from_calendar');
  end if;

  if coalesce(v_noweeks,0) > 0 then
    v_checks := v_checks || jsonb_build_object('level','🔴',
      'text_ar', v2.ar_count(v_noweeks,'أسبوعٌ واحدٌ بلا تواريخ','أسبوعان بلا تواريخ',
                  'أسابيعَ بلا تواريخ','أسبوعًا بلا تواريخ')
                 ||' في تقويمك — ولا يُحسب عليها توزيع','fix',null);
  end if;

  if v_refyear is not null and exists (
       select 1 from v2.school_weeks(p_school) w group by w.term_no having bool_and(w.is_exam = false)) then
    v_checks := v_checks || jsonb_build_object('level','🟠',
      'text_ar','فصلٌ في تقويمك بلا أسبوعِ اختبارٍ موسوم — وأسبوعُ الاختبار لا يدخل في توزيع المنهج','fix',null);
  end if;

  if coalesce(v_cust,0) > 0 then
    v_checks := v_checks || jsonb_build_object('level','ℹ️',
      'text_ar', v2.ar_count(v_cust,'أسبوعٌ واحدٌ مخصَّصٌ لمدرستك','أسبوعان مخصَّصان لمدرستك',
                  'أسابيعَ مخصَّصةٍ لمدرستك','أسبوعًا مخصَّصًا لمدرستك')
                 ||' — والأصلُ معروضٌ بجانبه، ويُعاد بزرّ','fix','v2_calendar_week_reset');
  end if;

  if jsonb_array_length(v_checks) = 0 then
    v_checks := v_checks || jsonb_build_object('level','✅',
      'text_ar','تقويمُك مكتملٌ — مسارٌ محدَّدٌ وسنةٌ حاليّةٌ وفصولٌ وأسابيعُ بتواريخها','fix',null);
  end if;

  select jsonb_build_object(
    'scope', (select jsonb_build_object('key',cs.key,'label_ar',cs.label_ar,
                'regions_ar',cs.regions_ar,'is_default',cs.is_default,
                'source_doc',cs.source_doc,'source_kind',cs.source_kind,'note',cs.note)
              from v2.calendar_scopes cs where cs.key = v_scope),
    'scopes', (select coalesce(jsonb_agg(jsonb_build_object('key',k.key,'label_ar',k.label_ar,
                 'is_default',k.is_default,'regions_ar',k.regions_ar,'source_kind',k.source_kind,
                 'weeks_n',(select count(*) from v2.calendar_weeks w
                              join v2.calendar_years yy on yy.id=w.year_id
                             where yy.scope_key=k.key))
                 order by k.key),'[]'::jsonb) from v2.calendar_scopes k),

    'year', (select jsonb_build_object('year',y.id,'name',y.name,'starts',y.starts_on,
               'ends',y.ends_on,'status',y.status) from v2.academic_years y where y.id=v_cyear),

    'terms', (select coalesce(jsonb_agg(jsonb_build_object('term',t.id,'no',t.number,
                'starts_g',t.starts_on,'starts_h',v2.fn_to_hijri(t.starts_on),
                'ends_g',t.ends_on,'ends_h',v2.fn_to_hijri(t.ends_on),
                'is_current',t.is_current) order by t.number),'[]'::jsonb)
              from v2.terms t where t.year_id=v_cyear),

    'ref_terms', (select coalesce(jsonb_agg(x order by x->>'term_no'),'[]'::jsonb) from (
        select jsonb_build_object(
          'term_no', w.term_no,
          'weeks_n', count(*),
          'exam_weeks_n', count(*) filter (where w.is_exam),
          'plan_weeks_n', count(*) filter (where not w.is_exam),
          'custom_n', count(*) filter (where w.is_custom),
          'from_h', min(w.from_h), 'to_h', max(w.to_h),
          'study_days', (select ts.study_days from v2.calendar_term_stats ts
                          where ts.year_id=v_refyear and ts.term_no=w.term_no),
          'summary_ar', 'الفصلُ '||w.term_no||' — '
            || v2.ar_count(count(*),'أسبوعٌ واحد','أسبوعان','أسابيع','أسبوعًا')
            || ' · للتوزيع '
            || v2.ar_count(count(*) filter (where not w.is_exam),
                 'أسبوعٌ واحد','أسبوعان','أسابيع','أسبوعًا')
        ) x
        from v2.school_weeks(p_school) w group by w.term_no) q),

    'weeks', (select coalesce(jsonb_agg(jsonb_build_object(
                'week_id',w.week_id,'term_no',w.term_no,'week_no',w.week_no,
                'from_h',w.from_h,'to_h',w.to_h,'from_g',w.from_g,'to_g',w.to_g,
                'h_months',w.h_months,'is_exam',w.is_exam,'note',w.note_ar,
                'is_current',(current_date between w.from_g and w.to_g),
                'is_custom',w.is_custom,'custom_why',w.custom_why,'custom_at',w.custom_at,
                'base_from_h',w.base_from_h,'base_to_h',w.base_to_h,'base_is_exam',w.base_is_exam,
                'study_days',(select count(*) from v2.calendar_days d
                               where d.week_id=w.week_id and d.day_kind='study'),
                'holidays',(select coalesce(jsonb_agg(distinct h.title_ar),'[]'::jsonb)
                              from v2.calendar_days d
                              join v2.calendar_holidays h on h.id=d.holiday_id
                             where d.week_id=w.week_id)
              ) order by w.term_no, w.week_no),'[]'::jsonb)
              from v2.school_weeks(p_school) w
             where (p_term is null or w.term_no=p_term)),

    'holidays', (select coalesce(jsonb_agg(jsonb_build_object(
                  'title_ar',h.title_ar,'kind',h.holiday_kind,
                  'from_h',h.from_h,'to_h',h.to_h,'from_g',h.from_g,'to_g',h.to_g,
                  'stops_work',h.stops_work,'announced_by',h.announced_by,
                  'source_ref',h.source_ref,'note',h.note) order by h.from_g),'[]'::jsonb)
                 from v2.calendar_holidays h where h.year_id=v_refyear),

    'milestones', (select coalesce(jsonb_agg(jsonb_build_object(
                    'title_ar',m.title_ar,'kind',m.kind,'term_no',m.term_no,
                    'from_h',m.from_h,'from_g',m.from_g,'from_weekday',m.from_weekday,
                    'to_h',m.to_h,'to_g',m.to_g) order by m.ord),'[]'::jsonb)
                   from v2.calendar_milestones m where m.year_id=v_refyear),

    'entries', (select coalesce(jsonb_agg(jsonb_build_object('entry',e.id,'kind',e.kind,
                 'title',e.title,'from_g',e.starts_on,'from_h',v2.fn_to_hijri(e.starts_on),
                 'to_g',e.ends_on,'is_school_day',e.is_school_day,'source',e.source)
                 order by e.starts_on),'[]'::jsonb)
                from v2.calendar_entries e where e.school_id=p_school and e.removed_at is null
                  and (v_cyear is null or e.year_id=v_cyear or e.year_id is null)),

    'checks', v_checks,
    'summary_ar',
      case when v_scope is null then 'تقويمُك بلا مسارٍ — فحدِّد مسارَ إدارةِ تعليمك أوّلًا'
           when coalesce(v_weeks,0) = 0 then 'مسارُك بلا أسابيعَ منزَّلة'
           else coalesce((select cs.label_ar from v2.calendar_scopes cs where cs.key=v_scope),'مسارٌ')
                ||' — '||v2.ar_count(v_weeks,'أسبوعٌ واحد','أسبوعان','أسابيع','أسبوعًا')
                ||' في فصلين'
                ||case when v_terms=0 then ' · ولا فصلَ مُسجَّلٌ في سنتك بعد' else '' end
                ||case when coalesce(v_cust,0)>0 then ' · و'||v_cust||' مخصَّصٌ لك' else '' end
      end,
    'note_ar','التقويمُ مرجعٌ مشتركٌ لكلّ مدارس مسارك — ولا يُعدَّل الأصلُ من مدرسة. '
              ||'ولك أن تُخصّص أسبوعًا لمدرستك بسببٍ مُعلَن، فيُعرض تخصيصُك ومعه الأصل ويُعاد بزرّ. '
              ||'والهجريُّ هو الأصلُ في العرض والميلاديُّ بجانبه.'
  ) into v_r;
  return v_r;
end $function$
;

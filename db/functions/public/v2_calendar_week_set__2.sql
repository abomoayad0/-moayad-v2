-- public.v2_calendar_week_set(p_school uuid, p_term smallint, p_week smallint, p_from date, p_to date, p_is_exam boolean, p_reason text, p_note text, p_authority text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 4df3d9265b315ee0c74d1f69b8d63d9b
CREATE OR REPLACE FUNCTION public.v2_calendar_week_set(p_school uuid, p_term smallint, p_week smallint, p_from date DEFAULT NULL::date, p_to date DEFAULT NULL::date, p_is_exam boolean DEFAULT NULL::boolean, p_reason text DEFAULT NULL::text, p_note text DEFAULT NULL::text, p_authority text DEFAULT 'school'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare
  v_wid uuid; v_bf date; v_bt date; v_bx boolean;
  v_f date; v_t date; v_x boolean;
  v_auth text := coalesce(nullif(btrim(coalesce(p_authority,'')),''),'school');
  v_owner boolean := (v2.my_role() = 'owner');
  v_plan_before int; v_plan_after int; v_days_before int; v_days_after int;
begin
  perform v2.assert_my_school(p_school,'تخصيصَ أسبوعٍ في التقويم');
  perform v2.assert_role(array['principal','deputy','deputy_school','deputy_academic',
    'deputy_school_students','admin_assistant','admin_assistant_students','info_registrar'],
    'تخصيصَ أسبوعٍ في التقويم');

  if v_auth not in ('school','edu_dept','ministry') then
    raise exception 'جهةُ تخصيصٍ غيرُ معروفة — والمقبولُ: school (المدرسة) · edu_dept (إدارة التعليم) · ministry (الوزارة)';
  end if;
  if v_auth <> 'school' and not v_owner then
    raise exception 'تخصيصُ إدارةِ التعليم أو الوزارة لا يُسجَّل من المدرسة — فهو قرارُ جهةٍ أعلى، ويُثبّته إدارةُ النظام';
  end if;

  if btrim(coalesce(p_reason,'')) = '' then
    raise exception 'سببُ التخصيص مطلوبٌ — فمن يقرأ التقويمَ بعدك يجب أن يعرف لِمَ خُصِّص';
  end if;

  select w.id, w.from_g, w.to_g, coalesce(w.is_exam_week,false)
    into v_wid, v_bf, v_bt, v_bx
    from v2.schools s
    join v2.calendar_years y on y.scope_key = s.calendar_scope
    join v2.calendar_weeks w on w.year_id = y.id
   where s.id = p_school and w.term_no = p_term and w.week_no = p_week
   limit 1;

  if v_wid is null then
    raise exception 'لا أسبوعَ بهذا الرقم في الفصل % من تقويم مسار مدرستك', p_term;
  end if;

  v_f := coalesce(p_from, v_bf);
  v_t := coalesce(p_to,   v_bt);
  v_x := coalesce(p_is_exam, v_bx);

  if v_t < v_f then
    raise exception 'نهايةُ الأسبوع قبل بدايته — فراجِع التاريخين';
  end if;
  if v_f = v_bf and v_t = v_bt and v_x = v_bx and btrim(coalesce(p_note,'')) = '' then
    raise exception 'لا فرقَ بين ما أدخلتَه والأصل — ولا يُسجَّل تخصيصٌ بلا تغيير';
  end if;

  -- ═══ حارسُ أسابيع الدراسة — للمدرسة وحدَها ═══
  if v_auth = 'school' then
    select count(*) filter (where not w.is_exam) into v_plan_before
      from v2.school_weeks(p_school) w where w.term_no = p_term;

    v_plan_after := v_plan_before
      - case when v_x and not v_bx then 1 else 0 end
      + case when v_bx and not v_x then 1 else 0 end;

    if v_x <> v_bx then
      if v_x then
        raise exception 'لا يحقّ للمدرسة إنقاصُ أسابيع الدراسة — وأسابيعُ التوزيع في فصلك % وتصير % لو قُبل. وجعلُ أسبوعِ دراسةٍ أسبوعَ اختبارٍ قرارُ إدارةِ التعليم أو الوزارة، لا قرارُ مدرسة.', v_plan_before, v_plan_after;
      else
        raise exception 'لا يحقّ للمدرسة إلغاءُ أسبوعِ الاختبار المعتمد — فهو في التقويم المُلزِم، وتغييرُه قرارُ إدارةِ التعليم أو الوزارة.';
      end if;
    end if;

    v_days_before := (v_bt - v_bf);
    v_days_after  := (v_t - v_f);
    if v_days_after < v_days_before then
      raise exception 'لا يحقّ للمدرسة اختصارُ أسبوعٍ دراسيّ — فمدّتُه في التقويم % أيّامٍ وأنت تجعلها %. وتقصيرُ الأسبوع إنقاصٌ لأيّام الدراسة، وهو لإدارةِ التعليم أو الوزارة.', v_days_before+1, v_days_after+1;
    end if;
  end if;

  update v2.calendar_week_overrides
     set voided_at = now(), voided_by = v2.current_person(),
         void_why = 'حلَّ محلَّه تخصيصٌ أحدث'
   where school_id = p_school and week_id = v_wid and voided_at is null;

  insert into v2.calendar_week_overrides
    (school_id, week_id, from_g, to_g, from_h, to_h, is_exam_week, note_ar,
     reason_ar, set_by, authority)
  values (p_school, v_wid, v_f, v_t, v2.fn_to_hijri(v_f), v2.fn_to_hijri(v_t),
          v_x, nullif(btrim(coalesce(p_note,'')),''), btrim(p_reason),
          v2.current_person(), v_auth);

  return jsonb_build_object('ok',true,'term_no',p_term,'week_no',p_week,
    'authority',v_auth,
    'from_h',v2.fn_to_hijri(v_f),'to_h',v2.fn_to_hijri(v_t),'is_exam',v_x,
    'base_from_h',v2.fn_to_hijri(v_bf),'base_to_h',v2.fn_to_hijri(v_bt),'base_is_exam',v_bx,
    'summary_ar','خُصِّص الأسبوعُ '||p_week||' من الفصل '||p_term||' — '
      ||v2.fn_to_hijri(v_f)||' إلى '||v2.fn_to_hijri(v_t)||' هـ'
      ||case when v_auth='school' then ' · بقرار المدرسة'
             when v_auth='edu_dept' then ' · بقرار إدارة التعليم'
             else ' · بقرار الوزارة' end,
    'note_ar','والأصلُ باقٍ كما هو، وتقويمُ المدارس الأخرى لم يتغيّر. '
              ||'ولا تُنقص المدرسةُ أسابيعَ الدراسة — وذلك لإدارةِ التعليم والوزارة وحدَهما.');
end $function$
;

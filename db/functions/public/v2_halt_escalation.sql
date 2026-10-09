-- public.v2_halt_escalation(p_case uuid, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 42dee88c094e9153c75f244337a9c51e
CREATE OR REPLACE FUNCTION public.v2_halt_escalation(p_case uuid, p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare c record; st text; v_counsel boolean; v_ev uuid; g record;
begin
  perform v2.assert_role(array['principal'],'وقفَ التصعيد');
  select ac.*, s.full_name nm into c
    from v2.absence_cases ac join v2.students s on s.id=ac.student_id where ac.id=p_case;
  if c.id is null then raise exception 'الحالةُ غيرُ موجودة'; end if;
  perform v2.assert_my_school(c.school_id,'وقفَ التصعيد');
  if coalesce(c.escalation_halted,false) then
    raise exception 'تصعيدُ هذي الحالة موقوفٌ سلفًا — والسببُ: %', coalesce(c.halt_reason,'غيرُ مكتوب');
  end if;
  if length(btrim(coalesce(p_reason,''))) < 10 then
    raise exception 'وقفُ التصعيد لا يقع بلا سببٍ مكتوبٍ يبقى في السجلّ باسمك';
  end if;

  v_counsel := exists (select 1 from v2.counsel_cases cc
                        where cc.student_id = c.student_id);

  update v2.absence_cases
     set escalation_halted = true,
         halt_reason = btrim(p_reason)||' · قرارُ مدير المدرسة '||
                       coalesce(v2.fn_to_hijri(current_date)||' هـ','')||
                       case when v_counsel then ' · وللطالب حالةٌ عند الموجّه الطلابيّ'
                            else ' · ولا حالةَ له عند الموجّه — فيُحال إليه' end
   where id = p_case;

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
      ref_table,ref_id,visible_to,is_test)
  values (c.school_id,'other',current_date,c.student_id,
      'أُوقف تصعيدُ حالة المواظبة',
      'بقرارٍ من مدير المدرسة · '||btrim(p_reason)||
      ' — ولا يُخرج في هذي الحالة خطابٌ إلى الجهات، وتبقى الرعايةُ والمتابعةُ قائمةً',
      'absence_cases',p_case,'counselor_only',coalesce(c.is_test,false))
  returning id into v_ev;

  perform v2.log_action(c.school_id,c.student_id,'halt_escalation','أُوقف تصعيدُ حالة مواظبة',
    'absence_cases',p_case, jsonb_build_object('reason',btrim(p_reason),'counsel',v_counsel));

  return jsonb_build_object('ok',true,'case',p_case,'halted',true,
    'counsel_case', v_counsel,
    'note_ar','أُوقف التصعيد — ولا يخرج خطابٌ إلى الجهات في هذي الحالة · '||
      'والإخطارُ اليوميُّ لوليّ الأمر وبنودُ الرعاية والمتابعة تبقى عاملةً · '||
      case when v_counsel then 'وللطالب حالةٌ مفتوحةٌ عند الموجّه الطلابيّ'
           else '🔴 ولا حالةَ له عند الموجّه الطلابيّ — فأحِله إليه، فالوقفُ حمايةٌ لا إهمال' end
      ||' · والقرارُ موسومٌ باسمك وتاريخه، ويُرفع بـ v2_resume_escalation');
end $function$
;

-- public.v2_remedial_follow(p_referral uuid, p_responded boolean, p_note text, p_to_support boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5e542af42a42f9631ba1389d14cb1da6
CREATE OR REPLACE FUNCTION public.v2_remedial_follow(p_referral uuid, p_responded boolean, p_note text, p_to_support boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r record; v_min int; nm text; v_ev uuid;
begin
  perform v2.assert_role(array['counselor','deputy_students','deputy','principal'],
    'متابعةَ تنفيذ الخطّة العلاجيّة');
  select * into r from v2.remedial_referrals where id=p_referral and voided_at is null;
  if r.id is null then raise exception 'لا إحالةَ بهذا المعرّف'; end if;
  perform v2.assert_my_school(r.school_id,'متابعةَ تنفيذ الخطّة العلاجيّة');
  v_min := v2.rule_n(r.school_id,'reason_min_chars');
  if length(btrim(coalesce(p_note,''))) < v_min then
    raise exception 'المتابعةُ لا تُسجَّل بلا نصٍّ — وأقلُّه % حرفًا', v2.ar_num(v_min); end if;

  select v2.fn_display_name(full_name) into nm from v2.students where id=r.student_id;

  if coalesce(p_to_support,false) then
    if coalesce(p_responded,false) then
      raise exception 'التحويلُ للبرامج المساندة لمن لم يُبدِ تجاوبًا — ونصُّه: %',
        v2.cite_of('remedial.support_programs'); end if;
    -- إشعارُ وليّ الأمر شرطٌ منصوصٌ قبل التحويل
    insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
        ref_table,ref_id,visible_to,is_test)
    values (r.school_id,'other',current_date,r.student_id,
        'تحويلُ ابنكم إلى البرامج المساندة',
        'نُخبركم أنّ ابنَكم '||coalesce(nm,'')||' لم يُبدِ تجاوبًا مع البرامج العلاجيّة، '
        ||'ويُحوَّل إلى البرامج المساندة. وبيانُ المتابعة: '||btrim(p_note),
        'remedial_referrals',p_referral,'all',coalesce(r.is_test,false))
    returning id into v_ev;
  end if;

  update v2.remedial_referrals
     set responded=p_responded, respond_note=btrim(p_note),
         to_support_programs=coalesce(p_to_support,false),
         support_note=case when coalesce(p_to_support,false) then btrim(p_note) end,
         guardian_notified_at=case when coalesce(p_to_support,false) then now() else guardian_notified_at end
   where id=p_referral;

  return jsonb_build_object('ok',true,'referral',p_referral,'responded',p_responded,
    'to_support',coalesce(p_to_support,false),'event',v_ev,
    'summary_ar', case when coalesce(p_to_support,false)
      then 'حُوّل '||coalesce(nm,'الطالب')||' إلى البرامج المساندة — وأُشعر وليُّ أمره'
      else 'سُجّلت متابعةُ '||coalesce(nm,'الطالب')||case when p_responded then ' — وقد تجاوب' else ' — ولم يتجاوب بعد' end end,
    'note_ar', case when coalesce(p_to_support,false)
      then 'والإشعارُ شرطٌ منصوصٌ قبل التحويل — '||v2.cite_of('remedial.support_programs')
      else 'ومن لم يتجاوب يُحوَّل إلى البرامج المساندة بعد إشعار وليّ الأمر' end);
end $function$
;

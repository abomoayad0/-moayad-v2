-- public.v2_contacts_card(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2df5af454950084970e5b8f323f4d8a7
CREATE OR REPLACE FUNCTION public.v2_contacts_card(p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare n_b int; n_a int; n_n int;
begin
  perform v2.assert_my_student(p_student,'سجلّ الاتصال');
  select count(*) filter (where coalesce(source,'none')='behavior'),
         count(*) filter (where source='absence'),
         count(*) filter (where coalesce(source,'none')='none')
    into n_b, n_a, n_n
    from v2.guardian_contacts where student_id=p_student;

  return jsonb_build_object(
    'rows', public.v2_contacts_of(p_student),
    'counts', jsonb_build_object('behavior',n_b,'absence',n_a,'none',n_n),
    'summary_ar', case when n_b+n_a+n_n = 0 then 'لا اتّصالَ مُثبتًا بوليّ أمره'
      else btrim(concat_ws(' · ',
        case when n_b > 0 then v2.ar_count(n_b,'اتّصالٌ واحدٌ عن بندِ سلوك',
               'اتّصالان عن بنود سلوك','اتّصالاتٍ عن بنود سلوك','اتّصالًا عن بنود سلوك') end,
        case when n_a > 0 then v2.ar_count(n_a,'اتّصالٌ واحدٌ عن بندِ مواظبة',
               'اتّصالان عن بنود مواظبة','اتّصالاتٍ عن بنود مواظبة','اتّصالًا عن بنود مواظبة') end,
        case when n_n > 0 then v2.ar_count(n_n,'اتّصالٌ واحدٌ بلا بند',
               'اتّصالان بلا بند','اتّصالاتٍ بلا بند','اتّصالًا بلا بند') end)) end,
    'note_ar','السجلُّ يجمع اتّصالاتِ السلّمين — وكلُّ سطرٍ موسومٌ بمصدره');
end $function$
;

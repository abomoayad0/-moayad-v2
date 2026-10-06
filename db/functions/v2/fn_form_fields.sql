-- v2.fn_form_fields(p_form smallint, p_doc jsonb)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 dc3b5600a62ab23e4cf1e7f795dd0c13
CREATE OR REPLACE FUNCTION v2.fn_form_fields(p_form smallint, p_doc jsonb)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
AS $function$
select coalesce(jsonb_agg(jsonb_build_object('label', lbl, 'value',
  case lbl
    when 'اسم الطالب' then p_doc#>>'{student,name}'
    when 'اسم الطالب/الطالبة' then p_doc#>>'{student,name}'
    when 'الصف' then p_doc#>>'{student,grade_ar}'
    when 'الفصل' then p_doc#>>'{student,section}'
    when 'المرحلة' then p_doc->>'stage_ar'
    when 'تاريخ الميلاد' then nullif(p_doc#>>'{student,birth_h}','')||' هـ'
    when 'ولي أمر الطالب' then p_doc#>>'{guardians,0,name}'
    when 'ولي أمر الطالب/الطالبة' then p_doc#>>'{guardians,0,name}'
    when 'الموجه الطلابي' then p_doc->>'counselor_ar'
    when 'درجة المشكلة' then case when p_doc#>>'{record,degree_no}' is null then null
                                  else v2.degree_ar((p_doc#>>'{record,degree_no}')::int) end
    when 'نص المشكلة' then p_doc#>>'{record,problem_ar}'
    when 'المشكلة ودرجتها' then nullif(coalesce(p_doc#>>'{record,problem_ar}','')||
         coalesce(' — الدرجة '||(p_doc#>>'{record,degree_no}'),''),'')
    when 'يوم الواقعة' then p_doc#>>'{record,weekday_ar}'
    when 'تاريخها' then nullif(p_doc#>>'{record,occurred_h}','')||' هـ'
    when 'اليوم' then coalesce(p_doc#>>'{record,weekday_ar}', p_doc->>'today_weekday')
    when 'التاريخ' then coalesce(nullif(p_doc#>>'{record,occurred_h}','')||' هـ',
                                 nullif(p_doc->>'today_h','')||' هـ')
    when 'الإجراءات المقررة' then p_doc->>'actions_text'
    when 'عدد أيام الغياب بدون عذر' then p_doc#>>'{attendance,بلا_عذر}'
    when 'تاريخ الغياب' then p_doc->>'absence_dates'
    else null end) order by ord)
, '[]'::jsonb)
from unnest(coalesce((select fields_ar from v2.official_forms where form_no=p_form), array[]::text[]))
 with ordinality as t(lbl, ord)
$function$
;

-- v2.audit_fields_without_source()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b0823355ae75045f84dad7bd318dae68
CREATE OR REPLACE FUNCTION v2.audit_fields_without_source()
 RETURNS TABLE(form_no smallint, form_ar text, field_key text, label_ar text, input text, required boolean, why_ar text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select f.form_no, o.title_ar, f.key, f.label_ar, f.input, f.required,
         case when s.form_no is null
                then 'حقلٌ نصيٌّ لم يُعلَن منبعُه في form_field_source — فلا مكتبةَ ولا حسابَ ولا إعلانَ يد'
              else 'مُعلَنٌ ولا مكتبةَ له ولا حسابَ ولا وَسمَ «بيدك» — إعلانٌ ناقص' end
    from v2.form_schema f
    join v2.official_forms o on o.form_no = f.form_no
    left join v2.form_field_source s on s.form_no=f.form_no and s.field_key=f.key
   where f.input in ('longtext','text')
     and (s.form_no is null
          or (s.bank_key is null and s.compute_kind is null and not s.by_hand))
$function$
;

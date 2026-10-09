-- v2.denial_line_ar(p_abs integer, p_limit integer, p_year_days integer)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 01fffe6d597811abc0da79509a8e1864
CREATE OR REPLACE FUNCTION v2.denial_line_ar(p_abs integer, p_limit integer, p_year_days integer)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select case when p_abs = 0
      then 'لم يغب بغير عذرٍ يومًا واحدًا'
      else 'غاب بغير عذرٍ '||v2.ar_count(p_abs,'يومًا واحدًا','يومين','أيّام','يومًا') end
    || ' · وحدُّ الحرمان '||v2.ar_count(p_limit,'يومٌ واحد','يومان','أيّام','يومًا')
    || ' من أصل '||v2.ar_count(p_year_days,'يومٍ دراسيٍّ واحد','يومين دراسيَّين',
                               'أيّامٍ دراسيّة','يومًا دراسيًّا');
$function$
;

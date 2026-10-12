-- public.v2_staff_late_board(p_school uuid, p_fy smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3308cfad178f8c95e64fb4e386e1fc58
CREATE OR REPLACE FUNCTION public.v2_staff_late_board(p_school uuid, p_fy smallint DEFAULT NULL::smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_fy smallint; r jsonb; n_notice int; n_deduct int; n_excess int;
begin
  perform v2.assert_role(array['principal','deputy','deputy_school','admin_assistant',
    'admin_assistant_students'],'قراءةَ تقرير متابعة الدوام');
  perform v2.assert_my_school(p_school,'قراءةَ تقرير متابعة الدوام');
  v_fy := coalesce(p_fy, extract(year from current_date)::smallint);

  select coalesce(jsonb_agg(jsonb_build_object(
      'person', x.pid, 'name_ar', x.nm,
      'days_n', x.days_n, 'minutes_total', x.minutes_total, 'total_ar', x.hours_txt,
      'excused_n', x.excused_n, 'last_on', x.last_on,
      'notice_due', x.notice_due, 'notice_n', x.notice_n,
      'deduct_days_due', x.deduct_days_due, 'deduct_days_done', x.deduct_days_done,
      'state_ar', case
         when x.deduct_days_due > x.deduct_days_done then
           '🔴 يجب أمرُ حسمٍ بمقدار '||v2.ar_count(x.deduct_days_due - x.deduct_days_done,
             'يومٍ واحد','يومين','أيّامٍ','يومًا')
         when x.deduct_days_done > x.deduct_days_due then
           '🟠 أُعدّ حسمٌ يزيد عن الواجب — قُبل عذرٌ بعد الإعداد، فيُراجَع'
         when x.notice_due and x.notice_n = 0 then '🔴 يجب التنبيه'
         when x.notice_due then '🟢 نُبّه'
         else 'دون العتبة' end,
      'basis_ar','سياسةُ الدليل — س-١٦-ا-١ سياسة ٠٣ ص٣٢٦ · التنبيهُ عند '||v2.ar_num(x.notice_hours)
                 ||' ساعاتٍ وحسمُ يومٍ عن كلّ '||v2.ar_num(x.per_hours)||' ساعاتٍ في العام الماليّ'
    ) order by x.minutes_total desc, x.nm), '[]'::jsonb),
    count(*) filter (where x.notice_due and x.notice_n = 0),
    count(*) filter (where x.deduct_days_due > x.deduct_days_done),
    count(*) filter (where x.deduct_days_done > x.deduct_days_due)
    into r, n_notice, n_deduct, n_excess
    from (
      select pe.id pid, v2.fn_display_name(pe.full_name) nm, t.*
        from (select distinct sl.person_id from v2.staff_lateness sl
               where sl.school_id=p_school and sl.fiscal_year=v_fy and sl.voided_at is null) z
        join v2.people pe on pe.id = z.person_id
        cross join lateral v2.staff_late_tally(p_school, z.person_id, v_fy) t) x;

  return jsonb_build_object('ok',true,'fiscal_year',v_fy,'rows',r,
    'notice_due', n_notice, 'deduction_due', n_deduct, 'deduction_excess', n_excess,
    'summary_ar', case when jsonb_array_length(r)=0
      then 'لا تأخّرَ محصورًا لمنسوبٍ في عام '||v_fy
      else v2.ar_count(jsonb_array_length(r),'منسوبٌ واحدٌ محصورُ التأخّر','منسوبان محصورا التأخّر',
                       'منسوبين محصوري التأخّر','منسوبًا محصوري التأخّر')
           ||' · '||v2.ar_num(n_notice)||' يجب تنبيهُه · '||v2.ar_num(n_deduct)||' يجب حسمُه'
           ||case when n_excess>0 then ' · '||v2.ar_num(n_excess)||' حسمُه يزيد عن الواجب' else '' end end,
    'note_ar','والعامُ هنا ماليٌّ (ميلاديٌّ) لا دراسيٌّ، فالنصُّ يقول «خلال العام الماليّ» — '
      ||v2.cite_of('hr.late_threshold')
      ||' · ورفعُ أمر الحسم يقع في فارس خارجَ هذا النظام، وهذا يُعدّه ويحفظ مرجعَه'
      ||' · وإن زاد المُعدُّ عن الواجب فالنظامُ يقولها ولا يُلغي، فالإلغاءُ قرارُ مديرٍ لا حسابُ آلة.');
end $function$
;

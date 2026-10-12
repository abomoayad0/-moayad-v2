-- v2.audit_card_step_late()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 22f684ad3d6e43fb852c04b8105b3553
CREATE OR REPLACE FUNCTION v2.audit_card_step_late()
 RETURNS TABLE(obj text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select coalesce(v2.fn_display_name(pe.full_name),'—')||' — '||s.name_ar,
         'خطوةٌ مستحقّةٌ عليه تجاوزت موعدَها: «'||ds.title_ar||'» · فُتحت '
           ||v2.fn_to_hijri(ds.opened_on)||' وموعدُها '||v2.fn_to_hijri(ds.due_on),
         'خلل'
    from v2.card_due_steps ds
    join v2.schools s on s.id=ds.school_id
    left join v2.people pe on pe.id=ds.owner_person
   where ds.answered_at is null and ds.due_on < current_date
   order by ds.due_on
$function$
;

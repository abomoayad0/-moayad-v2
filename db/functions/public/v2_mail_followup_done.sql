-- public.v2_mail_followup_done(p_followup uuid, p_note text, p_evidence text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3a10fd92805330fce1876f68783c76a1
CREATE OR REPLACE FUNCTION public.v2_mail_followup_done(p_followup uuid, p_note text, p_evidence text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid;
begin
  if btrim(coalesce(p_note,''))='' then raise exception 'لا يُغلق بند وارد بلا بيان ما تمّ'; end if;
  select m.school_id into sc from v2.mail_followups f join v2.mail_items i on i.id=f.item_id
   join v2.incoming_mail m on m.id=i.mail_id where f.id=p_followup;
  perform v2.assert_my_school(sc,'إغلاق بند وارد');
  update v2.mail_followups set status='done', done_at=now(), done_by=v2.current_person(),
    close_note=p_note, evidence_ref=p_evidence
   where id=p_followup
     and (person_id = v2.current_person() or role_ar = v2.role_ar(v2.my_role()));
  if not found then raise exception 'لم يُوجَّه إليك هذا البند، أو أُغلق سلفًا'; end if;
  update v2.incoming_mail m set status='closed', closed_at=now()
   where m.id = (select i.mail_id from v2.mail_followups f join v2.mail_items i on i.id=f.item_id where f.id=p_followup)
     and not exists (select 1 from v2.mail_items i2 join v2.mail_followups f2 on f2.item_id=i2.id
                     where i2.mail_id=m.id and f2.status<>'done');
end $function$
;

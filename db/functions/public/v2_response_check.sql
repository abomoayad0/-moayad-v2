-- public.v2_response_check(p_record uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 aa9b232364a62bbf790b47df8947fd49
CREATE OR REPLACE FUNCTION public.v2_response_check(p_record uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r record; pl record; pre int; post int; dts text; st text; byw text;
begin
  select br.*, cp.text_ar ptext, cp.repeat_key rk into r
    from v2.behavior_records br join v2.conduct_problems cp on cp.id=br.problem_id
   where br.id=p_record;
  if r.id is null then raise exception 'الرصدةُ غيرُ موجودة'; end if;
  perform v2.assert_my_student(r.student_id,'قياس الاستجابة');

  select * into pl from v2.behavior_plans
   where student_id=r.student_id and status='final'
   order by coalesce(final_at,created_at) desc limit 1;

  if pl.id is null then
    return jsonb_build_object('state','no-plan','can_refer',false,
      'why','لم تُعتمد خطّةُ تعديل السلوك بعد',
      'rule','عدمُ الاستجابة يُثبَت بما وقع بعد الخطّة: رُصد بعدها ⇒ لم يتعدّل · ولم يُرصد ⇒ تعدّل');
  end if;

  select count(*) into pre from v2.behavior_records x
   where x.student_id=r.student_id and x.problem_id=r.problem_id
     and x.status<>'voided' and x.created_at <= coalesce(pl.final_at,pl.created_at);
  select count(*), string_agg(x.occurred_on::text,' · ' order by x.occurred_on)
    into post, dts from v2.behavior_records x
   where x.student_id=r.student_id and x.problem_id=r.problem_id
     and x.status<>'voided' and x.created_at > coalesce(pl.final_at,pl.created_at);

  byw := case when r.rk='day'
    then 'سجلٌّ يوميٌّ يُقفل — فسكوتُه إثباتُ التزام'
    else 'شهادةُ معلّم الفصل — فالسلوكُ لا يُرصد آليًّا' end;

  st := case when post > 0 then 'failed' else 'improved' end;
  return jsonb_build_object(
    'state', st,
    'state_ar', case st when 'failed' then 'لم يتعدّل' else 'تعدّل' end,
    'can_refer', (st='failed'),
    'pre', pre, 'pre_ar', v2.ar_num(pre),
    'post', post, 'post_ar', v2.ar_num(post),
    'dates', dts, 'by', byw,
    'plan', pl.id, 'plan_at', coalesce(pl.final_at,pl.created_at),
    'why', case when st='failed'
      then 'تكرّر السلوكُ '||v2.ar_num(post)||' مرّةً بعد اعتماد الخطّة'
      else 'لم يُرصد بعد اعتماد الخطّة — فالاستجابةُ حاصلة، ولا تُفتح الإحالة' end);
end $function$
;

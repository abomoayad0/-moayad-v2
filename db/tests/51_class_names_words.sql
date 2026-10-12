-- فحص ٥١ · الصفُّ باسمه (class_ar) في كلّ باب · v2_my_now_board · والنصوصُ الثلاثةُ المصلَحة · وكتلُ الولاء
-- بحسابَي معلّم الموادّ والمساعد الإداريّ الحقيقيَّين · داخل begin…rollback
begin;
set local lock_timeout = '5s';
set local statement_timeout = '60s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"5e17dd28-15ef-4c80-b7ba-0cb3d9e4141d","role":"authenticated"}';
do $$ declare r jsonb; begin
  r := public.v2_my_now_board(current_setting('t.school')::uuid);
  perform set_config('t.s1','① v2_my_now_board ⇐ نوعُه '||jsonb_typeof(r)||' · مفاتيح '||coalesce((select string_agg(k,',' order by k) from jsonb_object_keys(r) k),'∅')||' · أوّلُ صفّ '||coalesce((r->'rows'->0)::text,'لا حصّةَ الآن'),true);
exception when others then perform set_config('t.s1','① v2_my_now_board ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_students_find('حس',null,null,3,current_setting('t.school')::uuid);
  perform set_config('t.s2','② v2_students_find (المعلّم) ⇐ class_ar '||coalesce(r->'rows'->0->>'class_ar','∅')||' · guardians_ar '||coalesce(r->'rows'->0->>'guardians_ar','∅'),true);
exception when others then perform set_config('t.s2','② ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_loyalty_catalog();
  perform set_config('t.s3','③ v2_loyalty_catalog ⇐ rewards[0] price_ar '||coalesce(r->'rewards'->0->>'price_ar','∅')||' · stock_ar '||coalesce(r->'rewards'->0->>'stock_ar','∅')||' · needs_principal_ar '||coalesce(r->'rewards'->0->>'needs_principal_ar','∅')||' · sources[0] points_ar '||coalesce(r->'sources'->0->>'points_ar','∅')||' · week_cap_ar '||coalesce(r->'sources'->0->>'week_cap_ar','∅')||' ‖ rules_ar '||coalesce(r->>'rules_ar','∅'),true);
exception when others then perform set_config('t.s3','③ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; st uuid; w jsonb; begin
  select (x->>'student_id')::uuid into st from jsonb_array_elements(public.v2_loyalty_of_section((public.v2_my_sessions(current_date)->0->>'section')::uuid)->'rows') x limit 1;
  r := public.v2_card_open(st, current_date);
  w := public.v2_loyalty_wallet(st);
  perform set_config('t.s4','④ البطاقة ⇐ practices points_ar: '||coalesce((select string_agg(distinct x->>'points_ar',' | ') from jsonb_array_elements(r->'practices') x),'∅')||' ‖ once_ar '||coalesce((select x->>'once_ar' from jsonb_array_elements(r->'practices') x where x->>'once_ar' is not null limit 1),'∅')||' ‖ counts_ar '||coalesce(r->'practice_balance'->>'counts_ar','∅')||' ‖ totals_ar '||coalesce(w->>'totals_ar','∅'),true);
exception when others then perform set_config('t.s4','④ ⇐ رُفض: '||sqlerrm,true); end $$;
set local request.jwt.claims = '{"sub":"fad7dfa7-8f6f-4c5b-9fbf-c0a2c308476a","role":"authenticated"}';
do $$ declare r jsonb; begin
  r := public.v2_students_find('حس',null,null,3,current_setting('t.school')::uuid);
  perform set_config('t.s5','⑤ v2_students_find (المساعد) ⇐ class_ar '||coalesce(r->'rows'->0->>'class_ar','∅')||' · guardians_ar '||coalesce(r->'rows'->0->>'guardians_ar','∅'),true);
exception when others then perform set_config('t.s5','⑤ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; d date; begin
  r := public.v2_absence_notices(current_setting('t.school')::uuid, current_date);
  perform set_config('t.s6','⑥ v2_absence_notices ⇐ '||(r->>'summary_ar')||' · class_ar (أوّلُ من لم يُخطَر) '||coalesce(r->'not_sent'->0->>'class_ar',r->'sent'->0->>'class_ar','لا صفّ اليومَ'),true);
exception when others then perform set_config('t.s6','⑥ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_denial_board(current_setting('t.school')::uuid);
  perform set_config('t.s7','⑦ v2_denial_board ⇐ '||(r->>'summary_ar')||' · class_ar '||coalesce(r->'rows'->0->>'class_ar','لا صفّ'),true);
exception when others then perform set_config('t.s7','⑦ ⇐ رُفض: '||sqlerrm,true); end $$;
reset role;
select n, current_setting('t.s'||n, true) as result from generate_series(1,7) n;
rollback;

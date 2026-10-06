-- فحص ٢ · الأمن: مستخدمٌ موثَّقٌ لا حسابَ له في v2.app_users، أمام الجسور التي تحرس بـ
--   v2.my_grant() not in ('owner','admin')
-- فـ my_grant() ترجع له null، والشرط null، فلا يُرفع الاستثناء.
-- لا يطبع الفحصُ بياناتٍ شخصيّة: أعدادٌ فقط. وكلُّه داخل begin … rollback.
begin;

select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true),
       set_config('t.merit',(select min(id)::text from v2.conduct_merits),true),
       set_config('t.queued',(select count(*)::text from v2.outbox where status='queued'),true),
       set_config('t.errs',(select count(*)::text from v2.error_log),true);

set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000001","role":"authenticated"}';

do $$ declare n int; begin
  select count(*) into n from public.v2_errors(3650, null);
  perform set_config('t.r_errors','نفذ: '||n||' سطرًا',true);
exception when others then perform set_config('t.r_errors','رُفض: '||sqlerrm,true); end $$;

do $$ declare n int; p int; begin
  select count(*), count(to_phone) into n, p from public.v2_outbox_pull(1000);
  perform set_config('t.r_outbox','نفذ: سحب '||n||' رسالةً، منها '||p||' برقم جوّال، وعُلِّمت «sent»',true);
exception when others then perform set_config('t.r_outbox','رُفض: '||sqlerrm,true); end $$;

do $$ declare r jsonb; begin
  r := public.v2_opp_open(current_setting('t.school')::uuid, current_setting('t.merit')::int,
        null,'فحص غريب','الحصّة الأولى',null::smallint,null);
  perform set_config('t.opp', r->>'opp', true);
  perform set_config('t.r_open','نفذ: '||(r->>'ok'),true);
exception when others then perform set_config('t.r_open','رُفض: '||sqlerrm,true); end $$;

do $$ declare r jsonb; begin
  r := public.v2_opp_plan(nullif(current_setting('t.opp',true),'')::uuid, 'فحص');
  perform set_config('t.r_plan','نفذ: '||coalesce(r->>'ok',r::text),true);
exception when others then perform set_config('t.r_plan','رُفض: '||sqlerrm,true); end $$;

do $$ declare r jsonb; begin
  r := public.v2_opp_close(nullif(current_setting('t.opp',true),'')::uuid, 'فحص');
  perform set_config('t.r_close','نفذ: '||coalesce(r->>'ok',r::text),true);
exception when others then perform set_config('t.r_close','رُفض: '||sqlerrm,true); end $$;

reset role;

select 'v2_errors(3650)' as الجسر, current_setting('t.r_errors') as النتيجة, 'في السجلّ '||current_setting('t.errs') as المرجع
union all select 'v2_outbox_pull(1000)', current_setting('t.r_outbox'), 'في الطابور '||current_setting('t.queued')
union all select 'v2_opp_open',  current_setting('t.r_open'),  ''
union all select 'v2_opp_plan',  current_setting('t.r_plan'),  ''
union all select 'v2_opp_close', current_setting('t.r_close'), '';

rollback;

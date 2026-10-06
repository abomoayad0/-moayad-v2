-- فحص ١ · الأمن: هل تنفّذ جسورُ SECURITY DEFINER لمن لا هويّةَ له (anon) أو لمستخدمٍ بلا حسابٍ في v2.app_users؟
-- كلُّه داخل begin … rollback فلا يبقى منه أثر.
begin;

-- التحضير بصلاحيّة المالك: مدرسةُ طُفيل، وأوّلُ ممارسةٍ، وإعدادُ class_sections (جدولُه فيه school_id).
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true),
       set_config('t.merit',(select min(id)::text from v2.conduct_merits),true),
       set_config('t.key','class_sections',true),
       set_config('t.rows_all',(select count(*)::text||' صفًّا من '||count(distinct school_id)||' مدارس' from v2.class_sections),true);

-- ١) بلا هويّة: anon
set local role anon;
do $$ declare r jsonb; begin
  r := public.v2_opp_open(current_setting('t.school')::uuid, current_setting('t.merit')::int,
        null,'فحص anon','الحصّة الأولى',null::smallint,null);
  perform set_config('t.anon_open','نفذ: '||(r->>'ok'),true);
exception when others then perform set_config('t.anon_open','رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_setting_rows(current_setting('t.key'), null);
  perform set_config('t.anon_rows','نفذ: '||jsonb_array_length(r->'rows')||' صفًّا',true);
exception when others then perform set_config('t.anon_rows','رُفض: '||sqlerrm,true); end $$;
reset role;

-- ٢) مستخدمٌ موثَّق لا حسابَ له في المدرسة
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000001","role":"authenticated"}';
do $$ declare r jsonb; begin
  r := public.v2_opp_open(current_setting('t.school')::uuid, current_setting('t.merit')::int,
        null,'فحص غريب','الحصّة الأولى',null::smallint,null);
  perform set_config('t.str_open','نفذ: '||(r->>'ok'),true);
exception when others then perform set_config('t.str_open','رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_setting_rows(current_setting('t.key'), null);
  perform set_config('t.str_rows','نفذ: '||jsonb_array_length(r->'rows')||' صفًّا',true);
exception when others then perform set_config('t.str_rows','رُفض: '||sqlerrm,true); end $$;
reset role;

select 'anon · v2_opp_open'            as الفحص, current_setting('t.anon_open') as النتيجة
union all select 'anon · v2_setting_rows(مدرسة=null)', current_setting('t.anon_rows')
union all select 'غريب موثَّق · v2_opp_open',          current_setting('t.str_open')
union all select 'غريب موثَّق · v2_setting_rows(null)', current_setting('t.str_rows')
union all select 'الإعداد المقروء', current_setting('t.key')
union all select 'كلُّ صفوفه في القاعدة', current_setting('t.rows_all');

rollback;

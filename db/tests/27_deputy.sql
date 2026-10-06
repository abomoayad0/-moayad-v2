-- فحص ٢٧ · قراراتُ الوكيل — الإقفالُ وإعادةُ الفتح والأعذار، بالنداءات التي ترسلها deputy.js.
-- كلُّه داخل begin … rollback: يُقفل اليومُ ويُعاد فتحُه ويُبتّ في عذرٍ ثمّ يتراجع كلُّه. لا حسابَ يُمسّ ولا حذف.
-- الإصدار ٢: في الإصدار ١ رُفض إقفالُ يوم الطفيل كلُّه بقفل «الواقعة مرّةً في اليوم» (علّةٌ في القاعدة، السطر ٥)، ولم يكن عذرٌ منتظر.
-- فيُفحص الإقفالُ والفتحُ في مالك اليوم، ويُقدَّم عذران داخل التراجع (v2_submit_excuse) لطالبين غائبين في الطفيل ليُبتّ فيهما.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '30s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true), set_config('t.malik','f789f9ea-e474-49bc-86e0-3449258815f8',true), set_config('t.d',current_date::text,true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';

-- ① الطفيل: الإقفالُ (علّة الإصدار ١) والأعذار
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  perform set_config('t.a1',coalesce((select student_id::text from public.v2_day_list(current_setting('t.school')::uuid,current_setting('t.d')::date) where state='absent' order by student_no limit 1),''),true);
  perform set_config('t.a2',coalesce((select student_id::text from public.v2_day_list(current_setting('t.school')::uuid,current_setting('t.d')::date) where state='absent' order by student_no offset 1 limit 1),''),true);
  for s in select * from (values
    (1, 'الطفيل · مفاتيحُ الشاشة', null::text, $q$select 'close='||coalesce(r->'can'->>'close_day','—')||' · reopen='||coalesce(r->'can'->>'reopen_day','—')||' · excuse='||coalesce(r->'can'->>'decide_excuse','—') from (select public.v2_me() r) z$q$),
    (2, 'الطفيل · إعادةُ فتحِ يومٍ مفتوح', null, $q$select (select row_to_json(x)::text from public.v2_reopen_day(current_setting('t.school')::uuid,current_setting('t.d')::date,'فحص') x)$q$),
    (3, 'الطفيل · الإقفال', null, $q$select (select row_to_json(x)::text from public.v2_close_day(current_setting('t.school')::uuid,current_setting('t.d')::date) x)$q$),
    (4, 'الطفيل · تقديمُ عذرٍ لغائبٍ أوّل (تجهيز)', 'claim', $q$select public.v2_submit_excuse(nullif(current_setting('t.a1'),'')::uuid,current_setting('t.d')::date,current_setting('t.d')::date,'مراجعةُ مستشفى — فحص','guardian','in_person',null,null)::text$q$),
    (5, 'الطفيل · تقديمُ عذرٍ لغائبٍ ثانٍ (تجهيز)', 'claim2', $q$select public.v2_submit_excuse(nullif(current_setting('t.a2'),'')::uuid,current_setting('t.d')::date,current_setting('t.d')::date,'ظرفٌ عائليّ — فحص','guardian','whatsapp',null,null)::text$q$),
    (6, 'الطفيل · الأعذارُ المنتظرة', null, $q$select count(*)||' ‖ '||coalesce((select row_to_json(x)::text from public.v2_pending_excuses(current_setting('t.school')::uuid) x limit 1),'—') from public.v2_pending_excuses(current_setting('t.school')::uuid)$q$),
    (7, 'الطفيل · ردُّ عذرٍ بلا سبب', null, $q$select public.v2_decide_excuse(nullif(current_setting('t.claim'),'')::uuid,false,null,false)::text$q$),
    (8, 'الطفيل · ردُّه بسبب', null, $q$select public.v2_decide_excuse(nullif(current_setting('t.claim'),'')::uuid,false,'لا مستندَ — فحص',false)::text$q$),
    (9, 'الطفيل · قبولُ الآخر', null, $q$select public.v2_decide_excuse(nullif(current_setting('t.claim2'),'')::uuid,true,null,false)::text$q$),
    (10, 'الطفيل · الأعذارُ بعدُ', null, $q$select count(*)::text from public.v2_pending_excuses(current_setting('t.school')::uuid)$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, coalesce(r,''), true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;

-- الإصدار ٣: أصلحت القاعدةُ علّةَ السطر ٣ (الآليُّ يتخطّى من رُصد عليه يدويًّا ويضيف تأخّرَه إلى ملاحظة رصدته) — فالسطر ٣ هو فحصُ الإصلاح، وهنا ما بعده.
do $$ declare s record; r text; begin
  for s in select * from (values
    (19, 'الطفيل · إقفالٌ ثانٍ بعد السطر ٣', $q$select (select row_to_json(x)::text from public.v2_close_day(current_setting('t.school')::uuid,current_setting('t.d')::date) x)$q$),
    (20, 'الطفيل · اليومُ بعده', $q$select 'closed='||closed||' · reopened='||reopened from public.v2_day_summary(current_setting('t.school')::uuid,current_setting('t.d')::date)$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
select set_config('t.notes', (select count(*)||' ‖ '||coalesce(string_agg(distinct right(br.note,90),' | '),'—') from v2.behavior_records br
   where br.school_id=current_setting('t.school')::uuid and br.occurred_on=current_setting('t.d')::date and br.note like '%عند الإقفال%'), true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
do $$ declare s record; r text; begin
  for s in select * from (values
    (22, 'الطفيل · ما وقع بعد الإقفال', $q$select count(*)||' ‖ '||coalesce(string_agg(distinct kind,','),'—') from public.v2_day_log(current_setting('t.school')::uuid,current_setting('t.d')::date)$q$),
    (23, 'الطفيل · إعادةُ الفتح بسبب', $q$select (select row_to_json(x)::text from public.v2_reopen_day(current_setting('t.school')::uuid,current_setting('t.d')::date,'فحص ٢٧ الإصدار ٣') x)$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;

-- ② مالك: الإقفالُ وإعادةُ الفتح
select public.v2_act_as('deputy_students', current_setting('t.malik')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (11, 'مالك · اليومُ قبلُ', $q$select day_kind||' · closed='||closed||' · unrecorded='||unrecorded||'/'||enrolled from public.v2_day_summary(current_setting('t.malik')::uuid,current_setting('t.d')::date)$q$),
    (12, 'مالك · الإقفال', $q$select (select row_to_json(x)::text from public.v2_close_day(current_setting('t.malik')::uuid,current_setting('t.d')::date) x)$q$),
    (13, 'مالك · اليومُ بعد الإقفال', $q$select 'closed='||closed||' · reopened='||reopened from public.v2_day_summary(current_setting('t.malik')::uuid,current_setting('t.d')::date)$q$),
    (14, 'مالك · ما وقع بعد الإقفال', $q$select count(*)||' ‖ '||coalesce(string_agg(distinct kind,','),'—') from public.v2_day_log(current_setting('t.malik')::uuid,current_setting('t.d')::date)$q$),
    (15, 'مالك · إقفالٌ ثانٍ', $q$select (select row_to_json(x)::text from public.v2_close_day(current_setting('t.malik')::uuid,current_setting('t.d')::date) x)$q$),
    (16, 'مالك · إعادةُ الفتح بلا سبب', $q$select (select row_to_json(x)::text from public.v2_reopen_day(current_setting('t.malik')::uuid,current_setting('t.d')::date,'  ') x)$q$),
    (17, 'مالك · إعادةُ الفتح بسبب', $q$select (select row_to_json(x)::text from public.v2_reopen_day(current_setting('t.malik')::uuid,current_setting('t.d')::date,'فحص ٢٧') x)$q$),
    (18, 'مالك · اليومُ بعد إعادة الفتح', $q$select 'closed='||closed||' · reopened='||reopened from public.v2_day_summary(current_setting('t.malik')::uuid,current_setting('t.d')::date)$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
-- خارجَ الدور (الجدولُ محروسٌ بـ RLS): الرصداتُ اليدويّةُ التي أُضيف إليها تأخّرُ الإقفال — قبل إعادة الفتح تُقرأ من t.notes
select set_config('t.s21','الطفيل · رصداتٌ يدويّةٌ أُضيف إليها تأخّرُ الإقفال (قبل إعادة الفتح) ⇐ '||coalesce(nullif(current_setting('t.notes',true),''),'—'),true);
select n::text as "#", left(current_setting('t.s'||n),700) as النتيجة from generate_series(1,23) n
union all select 'أ', 'a1 '||coalesce(nullif(current_setting('t.a1'),''),'—')||' · a2 '||coalesce(nullif(current_setting('t.a2'),''),'—');
rollback;

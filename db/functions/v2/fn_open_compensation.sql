-- v2.fn_open_compensation(p_record uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9b69821cfc9105e29f1bd0df8c198209
CREATE OR REPLACE FUNCTION v2.fn_open_compensation(p_record uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r record; v_ded numeric; v_merit record; nid uuid; v_open record; v_free int;
begin
  select br.* into r from v2.behavior_records br where br.id = p_record;
  if r.id is null then return jsonb_build_object('kind','opportunity','text','لا رصدة'); end if;

  select coalesce(sum(-bl.points),0) into v_ded from v2.behavior_ledger bl
   where bl.record_id = p_record and bl.kind='deduction';

  -- ① هل التحق الطالبُ بفرصةٍ مفتوحةٍ سلفًا؟
  if exists (select 1 from v2.merit_entries me
              join v2.merit_opportunities o on o.id = me.opp_id
             where me.student_id = r.student_id and o.state='مفتوحة'
               and me.lifted_at is null) then
    return jsonb_build_object('kind','opportunity',
      'text','الطالبُ مُلتحقٌ بفرصةِ تعويضٍ مفتوحةٍ — ولم تُفتح جديدة');
  end if;

  -- ② وهل في المدرسة عرضٌ مفتوحٌ يستطيع الالتحاقَ به؟
  select o.*, (select count(*) from v2.merit_entries me2
                where me2.opp_id = o.id and me2.lifted_at is null) joined
    into v_open
    from v2.merit_opportunities o
   where o.school_id = r.school_id and o.state = 'مفتوحة'
     and coalesce(o.year_id, r.year_id) = r.year_id
   order by o.opened_at desc nulls last limit 1;

  if v_open.id is not null then
    v_free := greatest(coalesce(v_open.capacity,0) - coalesce(v_open.joined,0), 0);
    if v_free > 0 then
      return jsonb_build_object('kind','opportunity','opp',v_open.id,
        'text','في المدرسة فرصةُ تعويضٍ مفتوحةٌ يتقدّم إليها الطالبُ من صفحته — «'||
               coalesce(v_open.title_ar,'فرصة')||'» · والمتاحُ '||v2.ar_num(v_free)||
               ' · ولم تُفتح جديدة');
    end if;
  end if;

  -- ③ ولا عرضَ متاحًا: يُفتح عرضٌ — أقربُ ما لا يتجاوز المحسوم، وإلا أصغرُ ما في الدليل
  select m.* into v_merit from v2.conduct_merits m
   where m.points <= greatest(v_ded,1) order by m.points desc, m.id limit 1;
  if v_merit.id is null then
    select m.* into v_merit from v2.conduct_merits m order by m.points, m.id limit 1;
  end if;
  if v_merit.id is null then
    return jsonb_build_object('kind','opportunity',
      'text','لم تُفتح فرصةٌ — لا بنودَ تعويضٍ مضبوطةٌ في لوحة التحكّم');
  end if;

  insert into v2.merit_opportunities(school_id,merit_id,year_id,term_no,kind,
      title_ar,when_ar,capacity,state,held_by,is_test)
  values (r.school_id, v_merit.id, r.year_id, r.term_no, 'فرديّة',
      v_merit.text_ar, 'متاحةٌ الآن', 30, 'مفتوحة', r.recorded_by,
      coalesce((select test_mode from v2.schools where id=r.school_id),false))
  returning id into nid;

  return jsonb_build_object('kind','opportunity','opp',nid,
    'points', v_merit.points, 'deducted', greatest(v_ded,1),
    'text','فُتحت فرصةُ تعويضٍ وزنُها '||v2.ar_num(v_merit.points)||' درجة يتقدّم إليها الطالبُ من صفحته'||
      case when v_merit.points > greatest(v_ded,1)
        then ' · والمحسومُ '||v2.ar_num(greatest(v_ded,1))||
             ' — فأصغرُ فرصةٍ في الدليل أكبرُ من المحسوم، ولا تقع فرصةٌ بأقلَّ منها'
        else '' end);
end
$function$
;

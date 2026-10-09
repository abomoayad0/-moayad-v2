-- v2.audit_role_map_gaps()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ed05bb734bd9f9c9fe5ac847ec8106e8
CREATE OR REPLACE FUNCTION v2.audit_role_map_gaps()
 RETURNS TABLE(gap_kind text, gap_ar text, owner_role text, detail text, open_items integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  -- ① لفظٌ مزروعٌ ولا سطرَ له في الخريطة ⇒ لا يراه أحد
  select 'unmapped_role'::text,
         'لفظُ تكليفٍ في البيانات بلا ترجمةٍ في الخريطة — فلا يظهر لأحد'::text,
         t.owner_role,
         'في '||t.srcs::text||' — وجملتُها '||t.n::text||' بندًا'::text,
         t.n_open::integer
    from (
      select owner_role,
             string_agg(distinct src, ' و') srcs,
             count(*) n,
             count(*) filter (where st='open') n_open
        from ( select 'السلوك' src, owner_role, status st from v2.behavior_tasks
               union all select 'المواظبة', owner_role, status from v2.absence_tasks
               union all select 'الوارد', role_ar, status from v2.mail_followups ) u
       where owner_role is not null
       group by owner_role
    ) t
   where not exists (select 1 from v2.task_role_map m where m.owner_role = t.owner_role)

  union all

  -- ② ترجمةٌ إلى مفتاحِ دورٍ لا وجودَ له في جدول الأدوار ⇒ تُطابق صفرًا بلا خطأ
  select 'unknown_post_key'::text,
         'الخريطةُ تترجم إلى مفتاحِ دورٍ غيرِ موجودٍ في جدول الأدوار — فلا يُطابق أحدًا'::text,
         m.owner_role,
         'المفتاحُ المجهول: '||k::text,
         0
    from v2.task_role_map m, unnest(m.role_keys) k
   where not exists (select 1 from v2.posts p where p.key = k)

  union all

  -- ③ ترجمةٌ إلى لجنةٍ غيرِ مفعَّلةٍ أو بلا أعضاء في أيّ مدرسة
  select 'empty_committee'::text,
         'الخريطةُ تُطابق بعضويّة لجنةٍ لا أعضاءَ لها — فلا يرى بنودَها أحد'::text,
         m.owner_role,
         'اللجنة: '||coalesce(c.label_ar, m.committee_key),
         0
    from v2.task_role_map m
    left join v2.committees c on c.key = m.committee_key
   where m.committee_key is not null
     and not exists (select 1 from v2.committee_members cm
                      where cm.committee_key = m.committee_key
                        and (cm.ended_on is null or cm.ended_on >= current_date))

  union all

  -- ④ سطرٌ في الخريطة لا يُطابق شيئًا: لا دورَ ولا لجنةَ ولا سياقَ ولا خارجيٌّ
  select 'dead_map_row'::text,
         'سطرٌ في الخريطة لا يُطابق بشيء — لا دورَ ولا لجنةَ ولا سياقَ ولا وَسْمَ خارجيّ'::text,
         m.owner_role, 'سطرٌ معطَّل'::text, 0
    from v2.task_role_map m
   where cardinality(m.role_keys) = 0 and m.committee_key is null
     and m.needs_context is null and not m.is_external;
$function$
;

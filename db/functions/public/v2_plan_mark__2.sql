-- public.v2_plan_mark(p_plan uuid, p_lesson uuid, p_state text, p_why text, p_periods_used smallint, p_sections uuid[])
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 264d9382f8634d3b5fa5fb4e346d2931
CREATE OR REPLACE FUNCTION public.v2_plan_mark(p_plan uuid, p_lesson uuid, p_state text, p_why text, p_periods_used smallint, p_sections uuid[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare
  g record; v_title text; v_item uuid; v_me uuid := v2.current_person();
  v_secs uuid[]; v_all uuid[]; v_bad text; v_n int; v_state text; v_done int; v_tot int;
begin
  select * into g from v2.plan_guard(p_plan,'رصدَ حالة بندٍ');
  v_state := btrim(coalesce(p_state,''));
  if v_state not in ('planned','done','deferred','lost') then
    raise exception 'حالةٌ غيرُ معروفة — والمقبولُ: planned مخطَّطٌ · done أُنجز · deferred رُحّل · lost فات';
  end if;
  if v_state in ('deferred','lost') and btrim(coalesce(p_why,'')) = '' then
    raise exception 'السببُ مطلوبٌ عند الترحيل أو الفوات — فلا يُرحَّل درسٌ بلا سبب';
  end if;

  select i.id, l.title_ar into v_item, v_title
    from v2.lesson_plan_items i join v2.curriculum_lessons l on l.id=i.lesson_id
   where i.plan_id=p_plan and i.lesson_id=p_lesson;
  if v_item is null then raise exception 'هذا البندُ ليس في هذي الخطّة'; end if;

  select array_agg(s.section_id) into v_all from v2.plan_sections(p_plan) s;
  if v_all is null or array_length(v_all,1) = 0 then
    raise exception 'لا فصولَ لهذي الخطّة في جدول مدرستك — فلا يُرصد إنجازٌ على فراغ';
  end if;

  v_secs := coalesce(p_sections, v_all);
  select string_agg(coalesce(c.label_ar, x::text), ' · ') into v_bad
    from unnest(v_secs) x left join v2.class_sections c on c.id = x
   where not (x = any(v_all));
  if v_bad is not null then
    raise exception 'ليست من فصول هذي الخطّة: %', v_bad;
  end if;

  if v_state = 'planned' then
    update v2.lesson_item_progress
       set voided_at = now(), voided_by = v_me,
           void_why = coalesce(nullif(btrim(coalesce(p_why,'')),''),'أُعيد مخطَّطًا')
     where item_id = v_item and section_id = any(v_secs) and voided_at is null;
  else
    insert into v2.lesson_item_progress(item_id, section_id, state, periods_used,
                                        on_date, why_ar, by_person)
    select v_item, x, v_state,
           case when v_state='done'
                then coalesce(p_periods_used,(select periods from v2.lesson_plan_items where id=v_item))
                else null end,
           current_date, nullif(btrim(coalesce(p_why,'')),''), v_me
      from unnest(v_secs) x
    on conflict (item_id, section_id) where voided_at is null
    do update set state = excluded.state, periods_used = excluded.periods_used,
                  on_date = excluded.on_date, why_ar = excluded.why_ar,
                  by_person = excluded.by_person, at = now();
  end if;

  -- حالةُ البند مشتقّةٌ من فصوله — لا تُكتب بيد
  update v2.lesson_plan_items
     set state = v2.item_state(v_item),
         done_on = case when v2.item_state(v_item)='done' then current_date else null end,
         periods_used = (select max(pr.periods_used) from v2.lesson_item_progress pr
                          where pr.item_id=v_item and pr.voided_at is null),
         state_by = v_me, state_at = now(),
         state_why = nullif(btrim(coalesce(p_why,'')),'')
   where id = v_item;

  v_n := coalesce(array_length(v_secs,1),0);
  v_tot := coalesce(array_length(v_all,1),0);
  select count(*) into v_done from v2.lesson_item_progress
   where item_id=v_item and voided_at is null and state='done';

  return jsonb_build_object('ok',true,'item',v_item,'state',v2.item_state(v_item),
    'marked_sections',v_n,'sections_total',v_tot,'done_sections',v_done,
    'summary_ar',
      case v_state
        when 'done' then 'سُجّل «'||v_title||'» منجزًا في '
             ||v2.ar_count(v_n,'فصلٍ واحد','فصلين','فصولٍ','فصلًا')
        when 'deferred' then 'رُحّل «'||v_title||'» في '
             ||v2.ar_count(v_n,'فصلٍ واحد','فصلين','فصولٍ','فصلًا')
        when 'lost' then 'سُجّل «'||v_title||'» فائتًا في '
             ||v2.ar_count(v_n,'فصلٍ واحد','فصلين','فصولٍ','فصلًا')
        else 'أُعيد «'||v_title||'» مخطَّطًا في '
             ||v2.ar_count(v_n,'فصلٍ واحد','فصلين','فصولٍ','فصلًا') end
      || ' · والبندُ منجزٌ في '||v_done::text||' من '||v_tot::text
      || case when v_done = v_tot and v_tot > 0 then ' — فتمّ في فصولك كلِّها' else '' end);
end $function$
;

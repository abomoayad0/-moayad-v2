-- v2.fn_action_items_expanded(p_action integer)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a66508450e3b22b7fedfd1ec02b443df
CREATE OR REPLACE FUNCTION v2.fn_action_items_expanded(p_action integer)
 RETURNS TABLE(ord numeric, kind text, text_ar text, owner_role text, conditional boolean, cond_note text, origin text, item_id integer, from_step smallint)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare a record; it record; sub record; v_prev integer; v_ord numeric := 0;
begin
  select * into a from v2.conduct_actions where id = p_action;
  for it in select * from v2.conduct_action_items where action_id = p_action order by ord loop

    if it.inherits_step is not null then
      select id into v_prev from v2.conduct_actions
        where degree_no = a.degree_no and stage_scope = a.stage_scope and mode = a.mode
          and target = a.target and step_no = it.inherits_step;

      -- ① الموروثُ أوّلًا
      for sub in select * from v2.fn_action_items_expanded(v_prev) loop
        if it.excludes_kind is not null and sub.kind = it.excludes_kind then
          continue;
        end if;
        v_ord := v_ord + 1;
        ord := v_ord; kind := sub.kind; text_ar := sub.text_ar; owner_role := sub.owner_role;
        conditional := sub.conditional; cond_note := sub.cond_note; origin := sub.origin;
        item_id := sub.item_id; from_step := it.inherits_step;
        return next;
      end loop;

      -- ② ثمّ فعلُ البند نفسِه إن كان يُضيف — و«note» توارثٌ محضٌ لا يُضيف
      if coalesce(it.evidence_kind,'note') <> 'note' then
        v_ord := v_ord + 1;
        ord := v_ord; kind := it.kind;
        text_ar := it.text_ar || ' [الفعلُ المضافُ: ' ||
          coalesce((select label_ar from v2.evidence_kinds where key = it.evidence_kind),
                   it.evidence_kind) ||
          case when it.excludes_kind is not null
               then ' — تُغيَّر عن سابقتها ولا تُكرَّر]' else ']' end;
        owner_role := it.owner_role;
        conditional := it.conditional; cond_note := it.cond_note; origin := it.origin;
        item_id := it.id; from_step := a.step_no;
        return next;
      end if;

    else
      v_ord := v_ord + 1;
      ord := v_ord; kind := it.kind; text_ar := it.text_ar; owner_role := it.owner_role;
      conditional := it.conditional; cond_note := it.cond_note; origin := it.origin;
      item_id := it.id; from_step := a.step_no;
      return next;
    end if;
  end loop;
end
$function$
;

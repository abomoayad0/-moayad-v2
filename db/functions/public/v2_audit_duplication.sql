-- public.v2_audit_duplication()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e128dfc96b292a1753d6b3ec73b2eb37
CREATE OR REPLACE FUNCTION public.v2_audit_duplication()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare a jsonb; a2 jsonb; a3 jsonb; b jsonb; b2 jsonb; c jsonb; c2 jsonb; d jsonb;
        e jsonb; e2 jsonb; f jsonb; g jsonb; k jsonb;
        n1 int; n1b int; n2 int; n2m int; n3 int; n4 int; n5 int; n6 int; n7 int;
        n8 int;
begin
  perform v2.assert_role(array['principal','deputy','admin_assistant'],'مرآة التكرار');

  select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into a
    from v2.audit_citations_ranked() x where x.severity='row_write';
  select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into a2
    from v2.audit_citations_ranked() x where x.severity in ('refusal','display');
  select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into a3
    from v2.audit_citations_ranked() x where x.severity='comment';
  select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into b
    from v2.audit_kinds_vs_engine() x where x.has_form;
  select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into b2
    from v2.audit_kinds_vs_engine() x where not x.has_form;
  select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into c
    from v2.audit_task_vocabularies() x where x.family_ar='بنود' and x.diverges;
  select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into c2
    from v2.audit_task_vocabularies() x where x.family_ar='بنود';
  select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into d from v2.audit_superseded_doors() x;
  select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into e
    from v2.audit_ladder_tables() x where x.verdict_ar like 'نقصٌ%';
  select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into e2 from v2.audit_ladder_tables() x;
  select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into f from v2.audit_role_map_gaps() x;
  select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into g
    from v2.audit_ladder_tables_unscoped() x;
  select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into k
    from v2.audit_fields_without_source() x;

  n1 := jsonb_array_length(a); n1b := jsonb_array_length(a2);
  n2 := jsonb_array_length(b); n2m := jsonb_array_length(b2);
  n3 := jsonb_array_length(c); n4 := jsonb_array_length(d);
  n5 := jsonb_array_length(e); n6 := jsonb_array_length(f);
  n7 := jsonb_array_length(g);
  n8 := jsonb_array_length(k);

  return jsonb_build_object(
    'citations_in_rows', a,
    'citations_in_messages', a2,
    'citations_in_comments', a3,
    'kinds_missing_paper', b,
    'kinds_manual_by_design', b2,
    'task_vocabularies_diverging', c,
    'task_vocabularies_all', c2,
    'superseded_doors', d,
    'ladder_tables_gaps', e,
    'ladder_tables_all', e2,
    'ladder_tables_unscoped', g,
    'role_map_gaps', f,
    'fields_without_source', k,
    'counts', jsonb_build_object('citations_in_rows',n1,'citations_in_messages',n1b,
                'citations_in_comments',jsonb_array_length(a3),
                'kinds_missing_paper',n2,'kinds_manual',n2m,'vocabularies_diverging',n3,
                'superseded',n4,'ladder_tables_gaps',n5,'ladder_tables_unscoped',n7,
                'role_map_gaps',n6,'fields_without_source',n8),
    'verdict_ar', case when n1+n2+n3+n5+n6+n7+n8 = 0
      then 'لا تكرارَ يُكتب في صفٍّ · ولا تكليفَ لا يصل صاحبَه · '||
           'ولا جدولَ مجالٍ محجوبٌ عن سلّمٍ يخدمه · ولا حقلَ نصٍّ بلا منبع'||
           case when n1b > 0 then ' · ويبقى '||
             v2.ar_count(n1b,'استشهادٌ واحدٌ في رسالةٍ تُقال ولا تُخزَّن',
               'استشهادان في رسالتين','استشهاداتٍ في رسائلَ تُقال ولا تُخزَّن',
               'استشهادًا في رسالةٍ تُقال ولا تُخزَّن') else '' end||
           case when n4 > 0 then ' · و'||
             v2.ar_count(n4,'بابٌ مُستبدَلٌ قائمٌ ينتظر إذنَ الحذف',
               'بابان مُستبدَلان ينتظران إذنَ الحذف','أبوابٍ مُستبدَلةٍ تنتظر إذنَ الحذف',
               'بابًا مُستبدَلًا ينتظر إذنَ الحذف') else '' end
      else btrim(concat_ws(' · ',
        case when n8 > 0 then v2.ar_count(n8,'حقلُ نصٍّ بلا منبعٍ يُملأ منه',
               'حقلا نصٍّ بلا منبع','حقولِ نصٍّ بلا منبع','حقلَ نصٍّ بلا منبع') end,
        case when n6 > 0 then v2.ar_count(n6,'تكليفٌ لا يصل صاحبَه','تكليفان لا يصلان صاحبَيهما',
               'تكاليفَ لا تصل أصحابَها','تكليفًا لا يصل صاحبَه') end,
        case when n5 > 0 then v2.ar_count(n5,'جدولُ مجالٍ محجوبٌ عن سلّمٍ يخدمه',
               'جدولا مجالٍ محجوبان عن سلّمٍ يخدمهما','جداولِ مجالٍ محجوبةٍ عن سلّمٍ يخدمها',
               'جدولَ مجالٍ محجوبًا عن سلّمٍ يخدمه') end,
        case when n7 > 0 then v2.ar_count(n7,'جدولُ مجالٍ لم يُعلَن غرضُه',
               'جدولا مجالٍ لم يُعلَن غرضُهما','جداولِ مجالٍ لم يُعلَن غرضُها',
               'جدولَ مجالٍ لم يُعلَن غرضُه') end,
        case when n1 > 0 then v2.ar_count(n1,'استشهادٌ يُكتب في صفٍّ حقيقيّ',
               'استشهادان يُكتبان في صفوف','استشهاداتٍ تُكتب في صفوف',
               'استشهادًا يُكتب في صفٍّ حقيقيّ') end,
        case when n2 > 0 then v2.ar_count(n2,'نوعٌ له نموذجٌ ولا فرعَ يُخرجه',
               'نوعان لهما نموذجٌ ولا فرعَ يُخرجهما','أنواعٍ لها نماذجُ ولا فروعَ تُخرجها',
               'نوعًا له نموذجٌ ولا فرعَ يُخرجه') end,
        case when n3 > 0 then v2.ar_count(n3,'جدولُ بنودٍ حالُه خارجةٌ عن القاموس',
               'جدولا بنودٍ حالُهما خارجةٌ عن القاموس','جداولِ بنودٍ حالُها خارجةٌ عن القاموس',
               'جدولَ بنودٍ حالُه خارجةٌ عن القاموس') end,
        case when n4 > 0 then v2.ar_count(n4,'بابٌ مُستبدَلٌ قائم','بابان مُستبدَلان قائمان',
               'أبوابٍ مُستبدَلةٍ قائمة','بابًا مُستبدَلًا قائمًا') end)) end,
    'note_ar','قراءةٌ محضةٌ لا تكتب حرفًا · والاستشهادُ يُصنَّف بالأثر، والنوعُ بالورق، '||
              'وجدولُ المجال بأنواع بنود الأدلّة لا بمفتاحه · '||
              'وكلُّ حكمٍ معلَّلٌ ومعه ما يُناقضه إن وُجد');
end $function$
;

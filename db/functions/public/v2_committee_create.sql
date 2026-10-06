-- public.v2_committee_create(p_school uuid, p_key text, p_label text, p_purpose text, p_seats jsonb)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 847bc32004a2ad0af94508b4fb50ec25
CREATE OR REPLACE FUNCTION public.v2_committee_create(p_school uuid, p_key text, p_label text, p_purpose text, p_seats jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare k text; s jsonb; n int := 0;
begin
  -- 🔒 إنشاءُ لجنةٍ قرارُ مديرٍ لا قرارُ وكيل
  perform v2.assert_role(array['principal'],'إنشاءَ لجنةٍ مدرسيّة');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if btrim(coalesce(p_label,''))='' then raise exception 'اكتب اسمَ اللجنة'; end if;
  if p_seats is null or jsonb_array_length(p_seats)=0 then
    raise exception 'لا لجنةَ بلا مقاعد — وأقلُّها رئيسٌ ومقرّرٌ وعضو'; end if;

  k := coalesce(nullif(btrim(coalesce(p_key,'')),''),
                'sch_'||substr(md5(p_school::text||p_label),1,10));
  if exists (select 1 from v2.committees where key=k) then
    raise exception 'لجنةٌ بهذا المفتاح قائمةٌ سلفًا'; end if;

  insert into v2.committees(key,label_ar,is_permanent,requires_note,purpose,
      source_page,school_id,created_by)
  values (k,btrim(p_label),true,false,
      nullif(btrim(coalesce(p_purpose,'')),''),
      'اجتهادُ مدرسةٍ — لا نصَّ لها في الدليل التنظيميّ',
      p_school,v2.current_person());

  for s in select * from jsonb_array_elements(p_seats) loop
    if (s->>'seat_role') not in ('chair','member','rapporteur') then
      raise exception 'الصفة: رئيسٌ أو عضوٌ أو مقرّر'; end if;
    insert into v2.committee_seats(committee_key,ord,post_key,seat_role,seat_count,
        is_elected,elected_by,qualification)
    values (k,coalesce((s->>'ord')::smallint,n+1),
        nullif(s->>'post_key',''), s->>'seat_role',
        coalesce((s->>'seat_count')::smallint,1),
        coalesce((s->>'is_elected')::boolean, (s->>'post_key') is null),
        nullif(s->>'elected_by',''),
        'اجتهادُ مدرسةٍ — لا نصَّ لهذا المقعد في الدليل');
    n := n + 1;
  end loop;

  if not exists (select 1 from v2.committee_seats where committee_key=k and seat_role='chair') then
    raise exception 'لا لجنةَ بلا رئيس'; end if;
  if not exists (select 1 from v2.committee_seats where committee_key=k and seat_role='rapporteur') then
    raise exception 'لا لجنةَ بلا مقرّرٍ يكتب المحضر'; end if;

  insert into v2.committee_school_rules(school_id,committee_key,seat_role,quorum_mode,
      allow_remote,tie_rule,reason_ar)
  values (p_school,k,'','majority',true,'رئيس',
      'اجتهادُ مدرسةٍ — لا نصَّ له في الدليل التنظيميّ');
  return jsonb_build_object('ok',true,'committee',k,'seats',n);
end $function$
;

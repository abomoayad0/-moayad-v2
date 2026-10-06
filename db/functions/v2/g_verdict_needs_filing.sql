-- v2.g_verdict_needs_filing()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c763fe6e9fe8a89609082d0a7307d3d6
CREATE OR REPLACE FUNCTION v2.g_verdict_needs_filing()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  if new.verdict is not null and new.filed_at is null then
    raise exception 'لا تُقرّ مشاركةٌ قبل أن يرفع الطالبُ نموذجَه وشاهدَه'; end if;
  if new.filed_at is not null then
    if btrim(coalesce(new.what_ar,''))='' then
      raise exception 'لا يُرفع نموذجٌ بلا بيانِ ما فُعل'; end if;
    if btrim(coalesce(new.evidence_name,''))='' then
      raise exception 'المرفقُ إلزاميّ'; end if;
    if not v2.evidence_ok(new.id, new.evidence_name) then
      raise exception 'المرفقُ ليس لهذي المشاركة — ولا يُقبل مسارُ شاهدٍ لغيرها'; end if;
  end if;
  return new;
end $function$
;

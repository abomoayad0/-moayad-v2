-- v2.g_verdict_needs_filing()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f27ac09381a267878f106a6e6f2ef1c7
CREATE OR REPLACE FUNCTION v2.g_verdict_needs_filing()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  if new.verdict in ('نفّذ','نفّذ جزئيًّا') and new.filed_at is null then
    raise exception 'لا يُقرُّ تنفيذٌ قبل أن يرفع الطالبُ نموذجَه وشاهدَه'; end if;
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

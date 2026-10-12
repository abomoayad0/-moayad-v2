-- v2.say_lock(p_door text, p_state text, p_msg text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f50a214a424cedddf08dc6c0d9094221
CREATE OR REPLACE FUNCTION v2.say_lock(p_door text, p_state text, p_msg text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
declare s text;
begin
  s := case p_state
         when '23502' then 'لم تكتمل البيانات — حقلٌ إلزاميٌّ تُرك فارغًا'
         when '23505' then 'هذا مسجَّلٌ من قبل — ولا يُسجَّل مرّتين'
         when '23514' then 'القيمةُ لا تُقبل — خالفت شرطًا في القاعدة'
         when '23503' then 'المرجعُ غيرُ موجودٍ — فتحقّق من اختيارك'
         when '22007' then 'التاريخُ غيرُ صحيح'
         when '22008' then 'التاريخُ خارجَ المدى'
         when '22P02' then 'القيمةُ غيرُ صحيحةِ النوع'
         else 'لم يُقبل الطلب'
       end;
  raise warning 'LOCK_SLIP door=% state=% raw=%', p_door, p_state, p_msg;
  return s || ' · وهذا نقصٌ في الباب لا فيك — فأبلِغ عنه ليُسدَّ في موضعه';
end $function$
;

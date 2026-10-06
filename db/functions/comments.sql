-- functions/comments.sql
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.

-- ── fn_comments · md5 95d599d6862467cbdd626af083ecb65e
COMMENT ON FUNCTION v2.assert_role(p_allowed text[], p_what text) IS 'حارسُ الصفة. ومالكُ النظام (owner) يمرّ عليه بقرار مفرح ٦/١٠/٢٠٢٦ — ولا يمسُّ ذلك سرَّ الموجّه، فجسورُه تُحرس بـ v2.is_counselor لا بهذا الحارس.';
COMMENT ON FUNCTION v2.assert_student_or_kin(p_student uuid, p_what text) IS 'يمرّ الطالبُ ووليُّ أمره، وإلا فحارسُ المنسوبين. ولا يُنادى إلا في جسور البوّابة — فالكتابةُ على الطالب للمنسوبين وحدَهم';
COMMENT ON FUNCTION v2.behavior_score(p_student uuid, p_year uuid, p_term smallint) IS 'درجةُ السلوك: الإيجابيُّ ٨٠ سقفًا · والمتميّزُ ٢٠ سقفًا · والمجموعُ ١٠٠ — CONDUCT-1447-OFF ص15';
COMMENT ON FUNCTION v2.caller_kind(p_student uuid) IS 'صفةُ المتّصل من القاعدة لا من الشاشة. 🔑 والصفةُ المختارةُ تحكم: من اختار صفةً غيرَ الموجّه الطلابيّ لا يرى ما وُسم counselor_only ولو كان هو الموجّه — قرار مفرح ٥/١٠/٢٠٢٦: فصلٌ تامّ بين الصفات.';
COMMENT ON FUNCTION v2.evidence_ok(p_entry uuid, p_path text) IS 'المرفقُ يُقبل إن كان في مسار مشاركته: merit/<المدرسة>/<الطالب>/<المشاركة>/ — فلا يصلح شاهدُ طالبٍ لآخر';
COMMENT ON FUNCTION v2.fn_audit() IS 'فاحص البناء — 58 فحصاً. قراءة محضة. ويُشغَّل من محرّر SQL بصلاحية المالك وحده: نتائجه تشمل القاعدة كلها وفيها أسماء طلاب، فلا جسر له في public.';
COMMENT ON FUNCTION v2.fn_day_classes(p_school uuid, p_date date) IS 'فصول اليوم للرصد بالفصل. الفصل «مرصود» إذا لم يبقَ فيه طالب حالته unrecorded — والحكم في القاعدة لا في الشاشة.';
COMMENT ON FUNCTION v2.fn_day_log(p_school uuid, p_date date) IS 'سجل الوقائع اليومية: كل غياب وتأخر واستئذان ومخالفة سلوكية وإجراء غياب وقع في يوم واحد على مستوى المدرسة، مرتَّباً بوقته.';
COMMENT ON FUNCTION v2.fn_entitlement(p_school uuid) IS 'حاسب الاستحقاق: يعطي لكل وظيفة في المدرسة ما تستحقه بالدليل، وما هو مشغول، وحالته، ومعه أرقام القواعد وصفحاتها. لا يمنع شيئاً — يخبر فقط. conflict=true يعني تطابق أكثر من قاعدة بأعداد مختلفة (كتعارض 350 في الطفولة المبكرة).';
COMMENT ON FUNCTION v2.fn_find_student(p_q text, p_school uuid) IS 'بحث مرن عن الطالب: بالاسم الأصلي أو المعروض أو الإنجليزي، أو باسم ولي الأمر، أو برقم الطالب أو الهوية أو الجواز أو هوية ولي الأمر أو جواله. يوحّد الهمزات والتاء والألف المقصورة في البحث فقط، ويتجاهل 966 و0 في الجوال، ويقبل الكلمات متفرقة.';
COMMENT ON FUNCTION v2.fn_record_behavior(p_student uuid, p_problem integer, p_term smallint, p_period smallint, p_place text, p_note text, p_victim uuid, p_injury boolean, p_damage boolean, p_seizure boolean, p_seizure_legal boolean, p_by uuid) IS 'الحسمُ حيث نصّ الإجراءُ وحدَه · ولا حسمَ بعد آخر إجراء · والقفلُ يتبع طبيعةَ السلوك: ما يدوم اليومَ يُقفل باليوم · وما يتكرّر يُميَّز بالحصّة أو الوقت. ٦/١٠/٢٠٢٦';
COMMENT ON FUNCTION v2.is_counselor(p_school uuid) IS 'الموجّهُ بصفته المختارة — فمن بدّل صفتَه إلى غيرها لا يفتح دراسةَ الحالة ولا الجلسات';
COMMENT ON FUNCTION v2.merit_path_allows(p_path text, p_write boolean) IS 'حارسُ مسار شواهد التعويض — يُنادى من سياسات المخزن بصلاحيّة الدالّة لا بصلاحيّة المستخدم';
COMMENT ON FUNCTION v2.my_school(p_school uuid) IS 'المدرسةُ النافذةُ من الصفة المختارة أوّلًا، ثمّ من حساب المستخدم. أُصلح ٥/١٠/٢٠٢٦ — كان من school_id فارغٌ يمرّ على كلّ مدرسة.';
COMMENT ON FUNCTION v2.term_of_strict(p_school uuid, p_date date) IS 'الفصلُ الدراسيُّ لليوم: فصولُ المدرسة أوّلًا ثمّ التقويمُ الوزاريّ — وترجع فارغًا إن لم يُعرف، فلا يُفترض الفصلُ الأوّل صامتًا';
COMMENT ON FUNCTION public.v2_merits() IS 'ممارساتُ السلوك المتميّز — CONDUCT-1447-OFF ص18–19. وما points فيه فارغٌ يُقدَّر بتوصية اللجنة بما لا يتجاوز ستًّا';
COMMENT ON FUNCTION public.v2_student_timeline(p_student uuid, p_as text) IS 'الرؤيةُ تُحسب من صفة المتّصل في القاعدة؛ و`p_as` قيدٌ يضيّق ولا يوسّع. أُصلح ٥/١٠/٢٠٢٦ — كان يثق بما ترسله الشاشة فيسرّب سرَّ الموجّه.';


-- functions/comments.sql
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.

-- ── fn_comments · md5 99b28e2ee1e5630d6e2f9573156400b7
COMMENT ON FUNCTION v2.arrival_state(p_school uuid, p_at time without time zone) IS 'حالُ الوصول بحسب وقته: حاضرٌ قبل المهلة · متأخّرٌ بعدها · غائبٌ بعد حدّ التأخّر';
COMMENT ON FUNCTION v2.assert_role(p_allowed text[], p_what text) IS 'حارسُ الصفة. ومالكُ النظام (owner) يمرّ عليه بقرار مفرح ٦/١٠/٢٠٢٦ — ولا يمسُّ ذلك سرَّ الموجّه، فجسورُه تُحرس بـ v2.is_counselor لا بهذا الحارس.';
COMMENT ON FUNCTION v2.assert_student_or_kin(p_student uuid, p_what text) IS 'يمرّ الطالبُ ووليُّ أمره، وإلا فحارسُ المنسوبين. ولا يُنادى إلا في جسور البوّابة — فالكتابةُ على الطالب للمنسوبين وحدَهم';
COMMENT ON FUNCTION v2.audit_citations_ranked() IS 'استشهاداتُ الكود مصنَّفةً بالأثر · وحدُّها أنّ التصنيفَ بالسطر — فرسالةُ رفضٍ تمتدّ سطرين تُحسب عرضًا';
COMMENT ON FUNCTION v2.audit_hardcoded_citations() IS 'مُستبدَل بـ audit_citations_ranked — يعدُّ التعليقاتَ ورسائلَ الرفض ديْنًا كالذي يُكتب في الصفوف';
COMMENT ON FUNCTION v2.audit_kinds_without_branch() IS 'مُستبدَلٌ بـ v2.audit_kinds_vs_engine — فهذي تخلط النوعَ اليدويَّ بالتصميم بالنقص الحقيقيّ · تبقى حتى يأذن مفرح بحذفها';
COMMENT ON FUNCTION v2.audit_ladder_tables() IS 'المقياسُ السابع — جداولُ المجال وأيُّها يستحقّ الربطَ المرن · يعرض الدليلَ المضادَّ لحكمه في السطر نفسِه';
COMMENT ON FUNCTION v2.audit_links() IS 'مُستبدَلٌ في الحكم بـ audit_ladder_tables — يعدُّ كلَّ مفتاحٍ أجنبيٍّ نقصًا، ويبقى لعرض الروابط المرنة';
COMMENT ON FUNCTION v2.audit_role_map_gaps() IS 'المقياسُ السادس في المرآة — يكشف ما يُفرّغ باب «ما ينتظرني» بصمتٍ بلا خطأ';
COMMENT ON FUNCTION v2.audit_single_bound_links() IS 'مُستبدَلٌ بـ v2.audit_links — فهذي لا تُفرّق المشدودَ من المرن · تبقى حتى يأذن مفرح بحذفها';
COMMENT ON FUNCTION v2.audit_state_vocabularies() IS 'مُستبدَلٌ بـ v2.audit_task_vocabularies — فهذي تخلط حالَ البند بحال الكيان · تبقى حتى يأذن مفرح بحذفها';
COMMENT ON FUNCTION v2.behavior_score(p_student uuid, p_year uuid, p_term smallint) IS 'درجةُ السلوك: الإيجابيُّ ٨٠ سقفًا · والمتميّزُ ٢٠ سقفًا · والمجموعُ ١٠٠ — CONDUCT-1447-OFF ص15';
COMMENT ON FUNCTION v2.caller_kind(p_student uuid) IS 'صفةُ المتّصل من القاعدة لا من الشاشة. 🔑 والصفةُ المختارةُ تحكم: من اختار صفةً غيرَ الموجّه الطلابيّ لا يرى ما وُسم counselor_only ولو كان هو الموجّه — قرار مفرح ٥/١٠/٢٠٢٦: فصلٌ تامّ بين الصفات.';
COMMENT ON FUNCTION v2.day_status(p_school uuid, p_date date) IS 'يُفرّق ثلاثَ حالاتٍ كان البابُ يخلطها: يومٌ ليس في التقويم · إجازةُ أسبوعٍ أو رسميّة · ويومُ دراسة';
COMMENT ON FUNCTION v2.evidence_ok(p_entry uuid, p_path text) IS 'المرفقُ يُقبل إن كان في مسار مشاركته: merit/<المدرسة>/<الطالب>/<المشاركة>/ — فلا يصلح شاهدُ طالبٍ لآخر';
COMMENT ON FUNCTION v2.fn_action_items_expanded(p_action uuid) IS 'نسخةٌ لا تُنادى — أُنشئت بخطأٍ في نوع المعرّف · والعاملةُ هي نسخةُ integer · وتُحذف بإقرار مفرح';
COMMENT ON FUNCTION v2.fn_audit() IS 'فاحص البناء — 58 فحصاً. قراءة محضة. ويُشغَّل من محرّر SQL بصلاحية المالك وحده: نتائجه تشمل القاعدة كلها وفيها أسماء طلاب، فلا جسر له في public.';
COMMENT ON FUNCTION v2.fn_day_classes(p_school uuid, p_date date) IS 'فصول اليوم للرصد بالفصل. الفصل «مرصود» إذا لم يبقَ فيه طالب حالته unrecorded — والحكم في القاعدة لا في الشاشة.';
COMMENT ON FUNCTION v2.fn_day_log(p_school uuid, p_date date) IS 'سجل الوقائع اليومية: كل غياب وتأخر واستئذان ومخالفة سلوكية وإجراء غياب وقع في يوم واحد على مستوى المدرسة، مرتَّباً بوقته.';
COMMENT ON FUNCTION v2.fn_entitlement(p_school uuid) IS 'حاسب الاستحقاق: يعطي لكل وظيفة في المدرسة ما تستحقه بالدليل، وما هو مشغول، وحالته، ومعه أرقام القواعد وصفحاتها. لا يمنع شيئاً — يخبر فقط. conflict=true يعني تطابق أكثر من قاعدة بأعداد مختلفة (كتعارض 350 في الطفولة المبكرة).';
COMMENT ON FUNCTION v2.fn_find_student(p_q text, p_school uuid) IS 'بحث مرن عن الطالب: بالاسم الأصلي أو المعروض أو الإنجليزي، أو باسم ولي الأمر، أو برقم الطالب أو الهوية أو الجواز أو هوية ولي الأمر أو جواله. يوحّد الهمزات والتاء والألف المقصورة في البحث فقط، ويتجاهل 966 و0 في الجوال، ويقبل الكلمات متفرقة.';
COMMENT ON FUNCTION v2.fn_record_behavior(p_student uuid, p_problem integer, p_term smallint, p_period smallint, p_place text, p_note text, p_victim uuid, p_injury boolean, p_damage boolean, p_seizure boolean, p_seizure_legal boolean, p_by uuid) IS 'الحسمُ حيث نصّ الإجراءُ وحدَه · ولا حسمَ بعد آخر إجراء · والقفلُ يتبع طبيعةَ السلوك: ما يدوم اليومَ يُقفل باليوم · وما يتكرّر يُميَّز بالحصّة أو الوقت. ٦/١٠/٢٠٢٦';
COMMENT ON FUNCTION v2.fn_term_of(p_school uuid, p_date date) IS 'أقربُ فصلٍ زمنًا لما خرج عن الفصلين (كإجازة منتصف العام) — ولا يُفترض الأوّلُ إلّا إن لم يُعرف تقويم';
COMMENT ON FUNCTION v2.g_open_case_on_refer() IS 'مُعطَّل — بابُ فتح حالة الموجّه هو v2.ladder_auto وحدَه · ويُحذف المُثبِّتُ تمامًا بإقرار مفرح';
COMMENT ON FUNCTION v2.has_post(p_posts text[]) IS 'أله هذا التكليفُ أصالةً أو إنابةً في مدرسته النافذة؟ ولا يمرّ به owner — فالشاشةُ تظهر لمن يعمل فيها. قرار مفرح ٦/١٠/٢٠٢٦';
COMMENT ON FUNCTION v2.is_counselor(p_school uuid) IS 'الموجّهُ بصفته المختارة — فمن بدّل صفتَه إلى غيرها لا يفتح دراسةَ الحالة ولا الجلسات';
COMMENT ON FUNCTION v2.may_read_secret_mail() IS 'م35 بند 5: المحافظةُ على سرّيّة الوارد — والمديرُ والوكيلُ وحدَهما يقرآن السرّيّ · ومالكُ النظام';
COMMENT ON FUNCTION v2.merit_path_allows(p_path text, p_write boolean) IS 'حارسُ مسار شواهد التعويض — يُنادى من سياسات المخزن بصلاحيّة الدالّة لا بصلاحيّة المستخدم';
COMMENT ON FUNCTION v2.my_owner_roles(p_school uuid) IS 'ما يقع عليَّ من ألفاظ الدليل — بدوري أو بعضويّتي في لجنة';
COMMENT ON FUNCTION v2.my_post_keys() IS 'جميعُ مفاتيح أدوار المستعمل — لا الصفةُ الواحدةُ وحدَها';
COMMENT ON FUNCTION v2.my_school(p_school uuid) IS 'المدرسةُ النافذةُ من الصفة المختارة أوّلًا، ثمّ من حساب المستخدم. أُصلح ٥/١٠/٢٠٢٦ — كان من school_id فارغٌ يمرّ على كلّ مدرسة.';
COMMENT ON FUNCTION v2.task_form_no(p_kind text) IS 'قشرةٌ على v2.form_for_kind — والخريطةُ في جدول v2.task_kind_forms لا في الكود';
COMMENT ON FUNCTION v2.task_state(p_status text, p_standing boolean) IS 'الحالُ المعياريّةُ لكلّ بنود النظام: open · standing · done · skipped · refused · تُترجَم إليها قواميسُ السلوك والمواظبة والوارد — فلا يُكسر قيدٌ ولا يُحذف عمود';
COMMENT ON FUNCTION v2.term_of_strict(p_school uuid, p_date date) IS 'ثلاثةُ مسارات: فصلُ المدرسة · ثمّ أسبوعُ اليوم · ثمّ مدّةُ الفصل — والثالثُ يُدرك العطلَ والإجازاتِ داخل الفصل · ويبقى فارغًا لما خرج عن الفصلين حقًّا';
COMMENT ON FUNCTION v2.trg_tt_clash() IS 'حارسُ تضارب المعلّم في الجدول — ويحترم إقرارَ الإنسان إذا مُرّر v2.force_clash=on. ولا يقرأ weekday_ar فهو عمودٌ مولَّدٌ لا يُحسب قبل الإدراج. ٦/١٠/٢٠٢٦';
COMMENT ON FUNCTION public.v2_contacts_of(p_student uuid) IS 'يُرجع مصفوفةً كما كان — وزاد في كلّ سطرٍ source و source_ar و task و about · والعدّاتُ والخلاصةُ في v2_contacts_card';
COMMENT ON FUNCTION public.v2_mail_ack(p_mail uuid, p_signed boolean, p_refuse_reason text) IS 'مُستبدَلٌ بـ v2_mail_acknowledge — فهذي بلا مرفقٍ وبلا ردٍّ · تبقى حتى يأذن مفرح بحذفها';
COMMENT ON FUNCTION public.v2_mail_followup_done(p_followup uuid, p_note text, p_evidence text) IS 'مُستبدَلٌ بـ v2_mail_followup_close — فهذي بلا حارسِ «متابعتُك أنت» وبلا ردّ · تبقى حتى يأذن مفرح بحذفها';
COMMENT ON FUNCTION public.v2_merits() IS 'ممارساتُ السلوك المتميّز — CONDUCT-1447-OFF ص18–19. وما points فيه فارغٌ يُقدَّر بتوصية اللجنة بما لا يتجاوز ستًّا';
COMMENT ON FUNCTION public.v2_student_timeline(p_student uuid, p_as text) IS 'الرؤيةُ تُحسب من صفة المتّصل في القاعدة؛ و`p_as` قيدٌ يضيّق ولا يوسّع. أُصلح ٥/١٠/٢٠٢٦ — كان يثق بما ترسله الشاشة فيسرّب سرَّ الموجّه.';
COMMENT ON FUNCTION public.v2_students_board(p_school uuid, p_grade smallint, p_section text, p_q text) IS 'مُستبدَلٌ بالنسخة ذات الحدّ (خمسةُ وسائط) — يبقى متوافقًا ويُرجع المصفوفةَ كما كان، ويُنادي الجديدةَ فلا منطقَ مكرَّر';


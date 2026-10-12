# فحص ٥١ · الصفُّ باسمه في كلّ باب · v2_my_now_board · والنصوصُ المصلَحة

جرى مرّةً واحدةً في ١٢/١٠/٢٠٢٦ داخل `begin … rollback` بحسابَي معلّم الموادّ والمساعد الإداريّ. **النتيجة:** ٧ من ٧ كما يُنتظر.

| # | النتيجة |
|---|---|
| ١ | `v2_my_now_board` ⇐ كائن (`rows` · `count` · `summary_ar`) · `period_ar` «الحصّة الخامسة» · `time_ar` · `students_ar` «٨ طلّاب» · `section_label` ✅ |
| ٢ | `v2_students_find` (المعلّم) ⇐ `class_ar` «ثاني متوسط — أ» · `guardians_ar` «وليُّ أمرٍ واحد» ✅ |
| ٣ | `v2_loyalty_catalog` ⇐ `price_ar` «بـ١٥ نقطة» · `stock_ar` «بلا حدٍّ للعدد» · `points_ar` · `week_cap_ar` · `rules_ar` ✅ |
| ٤ | البطاقة ⇐ `points_ar` «بلا وزن» / «تُضيف ٠٫٥ إلى رصيد الممارسات»… · `once_ar` · `counts_ar` «لم يُرصد له شيءٌ هذا الفصل» · `totals_ar` «لا حركةَ في محفظته بعد» ✅ |
| ٥ | `v2_students_find` (المساعد) ⇐ `class_ar` · `guardians_ar` ✅ |
| ٦ | `v2_absence_notices` ⇐ لا غائبَ اليومَ — فلم يُرَ `class_ar` حيًّا |
| ٧ | `v2_denial_board` ⇐ لا صفّ — فلم يُرَ `class_ar` حيًّا |

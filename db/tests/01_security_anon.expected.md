# المخرَج المتوقَّع لـ 01_security_anon.sql

## التشغيل الثالث (2026-10-06، بعد إصلاح الجسور التسعة و caller_kind) — المخرَج المعتمَد ✅

| الفحص | النتيجة |
|---|---|
| anon · v2_opp_open | رُفض: permission denied for function v2_opp_open |
| anon · v2_setting_rows(مدرسة=null) | رُفض: permission denied for function v2_setting_rows |
| غريب موثَّق · v2_opp_open | رُفض: فتحُ فرص التعويض للجنة التوجيه الطلابيّ — ص١٢ بند ١٠ |
| غريب موثَّق · v2_setting_rows(null) | رُفض: لا حسابَ فعّالٌ لك في هذا النظام — ولا يُقبل قراءة إعدادات المدرسة |
| الإعداد المقروء | class_sections |
| كلُّ صفوفه في القاعدة | 6 صفًّا من 2 مدارس |

الصفوفُ الأربعة الأولى «رُفض»، وهذا هو المخرَج السليم.

## التشغيل الثاني (2026-10-06، بعد إغلاق منح anon) — للتاريخ

| الفحص | النتيجة |
|---|---|
| anon · v2_opp_open | رُفض: permission denied for function v2_opp_open |
| anon · v2_setting_rows(مدرسة=null) | رُفض: permission denied for function v2_setting_rows |
| غريب موثَّق · v2_opp_open | **نفذ: true** ⚠️ |
| غريب موثَّق · v2_setting_rows(null) | رُفض: لا حسابَ فعّالٌ لك في هذا النظام — ولا يُقبل قراءة إعدادات المدرسة |
| الإعداد المقروء | class_sections |
| كلُّ صفوفه في القاعدة | 6 صفًّا من 2 مدارس |

- anon: أُغلق. صارت الجسورُ الممنوحة له 0، ويرفضه PostgreSQL قبل أن يدخل الدالّة.
- الغريب الموثَّق في `v2_setting_rows`: أُغلق. صار `assert_role` يرفض من ليس له `my_grant()`.
- الغريب الموثَّق في `v2_opp_open`: **ما زال مفتوحًا.** هذا الجسر لا يمرّ بـ `assert_role`، بل يحرس نفسه بـ `seat is null and v2.my_grant() not in ('owner','admin')`. و`my_grant()` لم تتغيّر بصمتُها (md5 `4b05b1b4…`)، فما زالت ترجع null لمن لا حسابَ له، فيبقى الشرط null ولا يُرفض. التفصيل في `02_security_null_grant.sql`.

## التشغيل الأوّل (2026-10-06، قبل الإصلاح) — للتاريخ

| الفحص | النتيجة |
|---|---|
| anon · v2_opp_open | نفذ: true |
| anon · v2_setting_rows(مدرسة=null) | نفذ: 6 صفًّا (صفوف المدرستين) |
| غريب موثَّق · v2_opp_open | نفذ: true |
| غريب موثَّق · v2_setting_rows(null) | رُفض: تكليفك (بلا تكليف) لا يملك قراءة إعدادات المدرسة… |

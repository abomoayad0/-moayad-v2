# db/ — كود القاعدة مستخرَجًا منها

كلّ ما هنا مستخرَجٌ من القاعدة الحيّة `qbhuuuiyitsgumrgjkme` من الكتالوج (`pg_get_functiondef` و`pg_get_constraintdef` و`pg_get_triggerdef` و`pg_policies` و`pg_get_viewdef` وACL)، لا من الذاكرة ولا من الهجرات. ويحمل كلُّ كائنٍ بصمتَه md5، وقد طابقت كلُّ بصمةٍ نظيرتَها في القاعدة عند الاستخراج.

## المحتوى

| الملفّ | العدد |
|---|---|
| `tables/*.sql` — الأعمدة والمفاتيح والقيود والفهارس وتفعيل RLS والتعليقات | 131 جدولًا · 55 فهرسًا |
| `views/v_students.sql` | 1 |
| `functions/v2/*.sql` | 149 دالّة |
| `functions/public/*.sql` — الجسور `v2_*` | 158 |
| `functions/comments.sql` | 14 تعليقًا |
| `foreign_keys.sql` | 103 جدول لها مفاتيح خارجيّة |
| `triggers.sql` | 42 زنادًا على 35 جدولًا |
| `policies.sql` | 137 سياسةً على 131 جدولًا |
| `grants.sql` — صلاحيّات المخطّط والدوالّ (لا منحَ على الجداول في القاعدة) | — |
| `storage.sql` — دلو `v2-attachments` وسياساته الخمس `v2att_*` فقط | — |

ما ليس هنا عن قصد: كائنات النظام الآخر في `public` و`storage` (سياسات `docs_*` و`gift_cards_*` و`staff_voice_upload`)، والبيانات، والحسابات.

## ترتيب التطبيق على قاعدةٍ فارغة

يلزم وجود الامتدادَين `pgcrypto` و`uuid-ossp`، ومخطّطَي Supabase `auth` و`storage`.

1. `create schema v2;`
2. `tables/*.sql`
3. `foreign_keys.sql`
4. `views/v_students.sql`
5. `set check_function_bodies = off;` ثمّ `functions/v2/*.sql` و`functions/public/*.sql` و`functions/comments.sql`
6. `triggers.sql`
7. `policies.sql`
8. `grants.sql`
9. `storage.sql`

## الفحوص

في `tests/`: كلُّ ملفٍّ داخل `begin … rollback` لا يترك أثرًا، ومعه مخرَجُه المتوقَّع.

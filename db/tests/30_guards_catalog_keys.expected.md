# فحص ٣٠ · حرّاسُ الوقت · كتالوجُ النماذج · مفتاحا jadwal و delegation — ما رجع من القاعدة الحقيقيّة

جرى مرّةً واحدةً في ٦/١٠/٢٠٢٦ داخل `begin … rollback`. **النتيجة:** ٦ من ٧، وفي الثالث علّة.

| # | النتيجة |
|---|---|
| ١ | وصولٌ بلا وقت ⇐ **رُفض:** «اكتب وقتَ الوصول» ✓ |
| ٢ | انصرافٌ بلا وقت ⇐ **رُفض:** «اكتب وقتَ الانصراف» ✓ |
| **٣** | **🔴 اتّصالٌ بلا وسيلة ⇐ رُفض بالإنجليزيّة:** «null value in column "channel" … violates not-null constraint» |
| ٤ | `v2_forms_catalog` ⇐ ٢١: نماذج السلوك والمواظبة ١٧ · نماذج الحماية ٤، ولكلٍّ `no` · `no_ar` · `title` · `group` · `open` · `signed` ✓ |
| ٥ | كتالوجُ مدرسةٍ ليست له ⇐ **رُفض:** «ليست مدرستك» ✓ |
| ٦ | مفرح (وكيلُ شؤون الطلاب): jadwal false · delegation true · manage_settings true · fill_form true · wakeel true ✓ |
| ٧ | سعيد (الموجّه): jadwal false · delegation false · manage_settings false · muwajjih true ✓ |

## 🔴 السطر ٣

- **حارسُ `v2_contact_log`** هو `p_channel not in (…)`، وهذه المقارنةُ على الفارغ تعطي NULL لا true، فلا يقع الحارس. ومثلُه حارسُ النتيجة.
- **فالواجهةُ تحرسهما:** «اختر الوسيلة» · «اختر النتيجة».
- **والإصلاحُ في القاعدة:** `p_channel is null or p_channel not in (…)`.

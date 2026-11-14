/*
 * بلدية محافظة المندق — إعداد البطاقة.
 * المواضع مقيسة من بطاقة العينة (محمد أحمد محي الزهراني) بعد مطابقتها على القالب
 * (1297×2008 = 5.49×8.5 سم بدقة 600). كل cy = مركز الحبر عموديًا.
 */
window.CARD_CONFIG = {
  key: 'mandak',
  title: 'بلدية محافظة المندق',
  api: 'https://ybrcyagdhhgvtrlslmev.supabase.co/functions/v1/mandak-cards',
  assets: '/mandak/assets/',
  W: 1297, H: 2008,
  // الصورة دائرية: فتحة الدائرة نصف قطرها ~345 ومركزها (740,836)، والصورة أعرض قليلًا فلا يظهر فراغ
  photo: { x: 388, y: 484, w: 704, h: 704, shape: 'circle' },
  fields: ['honorific', 'full_name', 'department', 'national_id', 'employee_no'],
  honorifics: ['الأستاذ', 'الأستاذة', 'المهندس', 'المهندسة', 'الدكتور', 'الدكتورة'],
  front: [
    { k: 'honorific',  cx: 740, cy: 1330, size: 95, weight: 400, maxW: 980 },
    // الاسم سطر واحد كالعينة؛ لو طال كثير ينقسم سطرين بين الصفة والزخرفة
    { k: 'full_name',  cx: 740, cy: 1490, size: 75, weight: 700, maxW: 980, wrapAt: 0.8, wrapK: 0.85, gap: 1.25 },
    // الإدارة سطران إذا ما كفاها سطر — مثل بطاقة «مساعد رئيس البلدية…» في العينات
    { k: 'department', cx: 740, cy: 1795, size: 88, weight: 400, maxW: 980, wrapAt: 1, wrapK: 0.86, gap: 1.18, cy2: 1800 },
  ],
  back: [
    // الحجم أصغر من العينة (440) بطلب أبو علي لأن بعض الأرقام طويلة؛ والطويل لا يتعدى عرض إطار السجل
    { k: 'employee_no', cx: 590, cy: 814,  size: 340, weight: 900, font: 'CardNum', ltr: true, maxW: 820 },
    { k: 'national_id', cx: 553, cy: 1705, size: 122, weight: 900, font: 'CardNum', ltr: true, maxW: 780 },  // وسط الإطار الذهبي 117..990
  ],
};

/*
 * بلدية محافظة بني حسن — إعداد البطاقة.
 * الخلفي ثابت كامل بلا نصوص. الأمامي: الصورة في الإطار، الاسم، السجل المدني
 * داخل الإطار الذهبي، والإدارة تحت الزخرفة — لا صفة ولا رقم وظيفي في القالب.
 * المواضع مقيسة من بطاقة العينة (بدر بن عبد الرحمن الزهراني) على القالب 1297×2008.
 */
window.CARD_CONFIG = {
  key: 'banihasan',
  title: 'بلدية محافظة بني حسن',
  api: 'https://ybrcyagdhhgvtrlslmev.supabase.co/functions/v1/banihasan-cards',
  assets: '/banihasan/assets/',
  W: 1297, H: 2008,
  // داخل الإطار 398..874 × 450..999، والصورة أعرض بكسلين من كل جهة فلا يظهر فراغ
  photo: { x: 396, y: 448, w: 480, h: 553, shape: 'rect' },
  fields: ['full_name', 'department', 'national_id'],
  front: [
    { k: 'full_name',   cx: 650, cy: 1229, size: 80,  weight: 700, maxW: 1050, wrapAt: 0.8, wrapK: 0.8, gap: 1.2 },
    { k: 'national_id', cx: 653, cy: 1402, size: 120, weight: 900, font: 'CardNum', ltr: true, maxW: 780 },  // وسط الإطار الذهبي 217..1090
    { k: 'department',  cx: 650, cy: 1652, size: 90,  weight: 400, maxW: 1050, wrapAt: 1, wrapK: 0.86, gap: 1.18, cy2: 1690 },
  ],
  back: [],
};

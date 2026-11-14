/*
 * cards/api.js — الاتصال بدالة البلدية الحالية فقط (CARD_CONFIG.api).
 * كل بلدية لها دالتها وقسمها ومخزنها، فلا يوجد عنوان يجمع بلديتين.
 * لا مفاتيح هنا: الدالة لا تطلب مفتاحًا، واللوحة تُرسل كلمة مرورها فقط.
 */
(function (global) {
  'use strict';
  const URL_ = global.CARD_CONFIG.api;

  async function call(action, payload, adminPass) {
    const headers = { 'content-type': 'application/json' };
    if (adminPass) headers['x-admin-pass'] = adminPass;
    let res;
    try {
      res = await fetch(URL_, { method: 'POST', headers, body: JSON.stringify({ action, ...(payload || {}) }) });
    } catch (e) {
      throw new Error('تعذّر الاتصال — تأكد من الإنترنت وحاول مرة ثانية');
    }
    let data = null;
    try { data = await res.json(); } catch (e) { /* يُعالج تحت */ }
    if (!res.ok || !data || !data.ok) {
      const err = new Error((data && data.error) || 'خطأ غير متوقع، حاول مرة ثانية');
      err.status = res.status;
      throw err;
    }
    return data;
  }

  global.MandakApi = { call };
})(window);

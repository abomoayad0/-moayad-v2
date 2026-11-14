/*
 * cards/register.js — صفحة تسجيل الموظف، مشتركة لكل البلديات.
 * الصفحة تكلّم دالة بلديتها فقط (CARD_CONFIG.api).
 */
(function () {
  'use strict';
  const CFG = window.CARD_CONFIG;
  document.body.innerHTML = `
<header class="top"><h1>بيانات بطاقة الموظف</h1><p>${CFG.title}</p></header>
<main class="wrap" id="main">
  <div class="cols">
    <form class="panel" id="form" novalidate>
      <h2>بياناتك</h2>
      <div id="fields"></div>
      <div id="err" class="note err hidden"></div>
      <button class="btn block" id="send" type="submit">إرسال البيانات</button>
    </form>
    <section class="panel">
      <h2>معاينة بطاقتك</h2>
      <div id="preview"></div>
      <p style="color:var(--muted);font-size:.82rem;margin:10px 0 0">المعاينة تقريبية، والطباعة النهائية تراجعها البلدية.</p>
    </section>
  </div>
</main>
<main class="wrap hidden" id="done">
  <div class="panel done">
    <div class="tick">✓</div>
    <h2 id="doneTitle">تم استلام بياناتك</h2>
    <p>شكرًا لك. لو تبي تعدّل أي شي، سجّل مرة ثانية بنفس السجل المدني وتتحدّث بياناتك.</p>
    <button class="btn ghost" type="button" onclick="location.reload()">تسجيل موظف آخر</button>
  </div>
</main>`;

  const $ = (id) => document.getElementById(id);
  const form = MandakForm.create($('fields'), $('preview'));
  const send = $('send'), err = $('err');

  $('form').addEventListener('submit', async (e) => {
    e.preventDefault();
    err.classList.add('hidden');
    if (!form.validate()) return;
    send.disabled = true; send.textContent = 'جاري الإرسال…';
    try {
      const r = await MandakApi.call('register', { ...form.getData(), photo: form.newPhotoDataURL() });
      $('doneTitle').textContent = r.updated ? 'تم تحديث بياناتك' : 'تم استلام بياناتك';
      $('main').classList.add('hidden');
      $('done').classList.remove('hidden');
      window.scrollTo(0, 0);
    } catch (ex) {
      err.textContent = ex.message;
      err.classList.remove('hidden');
    } finally {
      send.disabled = false; send.textContent = 'إرسال البيانات';
    }
  });
})();

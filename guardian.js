// مؤيّد · بوّابة وليّ الأمر — «نماذج تنتظرك»: ما اعتُمد ووصل إليه.
// v2_guardian_me · v2_guardian_forms · v2_guardian_form_read · v2_guardian_form_reply · v2_guardian_form_note
// والتوقيع بـ v2_form_sign(p_entry, 'ولي الأمر', …). وما يلزمه (needs_sign · needs_reply) من القاعدة.
(function () {
  'use strict';

  const M = window.Moayad;
  const { $, el, toast, errText, showLoadErr } = M;
  M.state.screen = 'guardian';

  const SIGNER = 'ولي الأمر';
  const ui = { forms: [], read: new Set() };

  function ask(dlg) {
    return new Promise((resolve) => {
      dlg.addEventListener('close', () => resolve(dlg.returnValue), { once: true });
      dlg.returnValue = '';
      dlg.showModal();
    });
  }

  // نصّ النموذج بعناوينه كما ترسله القاعدة — لا تُترجم المفاتيح في الشاشة
  function fieldsOf(f) {
    const kv = f.fields_kv || f.fields;
    if (!Array.isArray(kv)) return null;
    const t = el('table', 'kv');
    for (const p of kv) {
      const tr = el('tr');
      tr.append(el('th', null, p.label || p.key || ''), el('td', null, p.value == null ? '—' : String(p.value)));
      t.appendChild(tr);
    }
    return t;
  }

  function signedList(f) {
    // signed أسماء من وقّع كما ترسلها القاعدة
    const s = Array.isArray(f.signed) ? f.signed : [];
    return s.map((x) => typeof x === 'string' ? 'وقّع: ' + x
      : (x.signer || '') + ': ' + (x.signed ? 'أقرّ' : 'امتنع' + (x.reason ? ' — ' + x.reason : '')) + (x.at_h ? ' · ' + x.at_h : ''));
  }

  function render() {
    const box = $('forms');
    box.textContent = '';
    const waiting = ui.forms.filter((f) => f.needs_sign || f.needs_reply || f.needs_note).length;
    $('formsTitle').textContent = 'نماذج تنتظرك' + (ui.forms.length ? ' — ' + waiting + ' تنتظر ردّك من ' + ui.forms.length : '');
    if (ui.forms.length === 0) { box.appendChild(el('div', 'empty', 'لا نماذج وصلتك.')); return; }
    for (const f of ui.forms) {
      const unread = !f.read_at && !ui.read.has(f.inbox_id);
      const c = el('div', 'ev gform' + (unread ? ' unread' : ''));
      const top = el('div', 'row1');
      top.append(el('div', 'name', f.title_ar || ('نموذج ' + f.form_no)),
        el('span', 'badge ' + (f.needs_sign || f.needs_reply || f.needs_note ? 'b-absent' : 'b-permitted'),
          f.needs_sign ? 'ينتظر توقيعك' : f.needs_reply ? 'ينتظر ردّك' : f.needs_note ? 'ينتظر رأيك' : unread ? 'جديد' : 'للاطّلاع'));
      c.appendChild(top);
      c.appendChild(el('div', 'meta', [f.student_ar, f.class_ar].filter(Boolean).join(' — ')));
      if (f.delivered_h) c.appendChild(el('div', 'meta', 'وصل في ' + f.delivered_h));
      if (f.source) c.appendChild(el('div', 'meta', 'السند: ' + f.source));

      const d = el('details');
      d.appendChild(el('summary', null, 'اقرأ النموذج'));
      const body = fieldsOf(f);
      d.appendChild(body || el('div', 'notice err', 'لم تُرسل القاعدة نصّ النموذج بعناوينه.'));
      for (const line of signedList(f)) d.appendChild(el('div', 'detail', line));
      // يُوسم مقروءاً عند فتحه أول مرّة
      d.addEventListener('toggle', () => { if (d.open) markRead(f); });
      c.appendChild(d);

      if (f.reply) c.appendChild(el('div', 'detail', 'ردّك: ' + f.reply));

      if (f.needs_sign) {
        const a = el('div', 'acts two');
        const y = el('button', 'a-accept', 'أقرّ');
        y.type = 'button';
        y.addEventListener('click', () => sign(f, true));
        const n = el('button', 'a-reject', 'امتنع بسبب');
        n.type = 'button';
        n.addEventListener('click', () => sign(f, false));
        a.append(y, n);
        c.appendChild(a);
      }
      if (f.needs_reply) {
        const opts = f.reply_options;
        if (Array.isArray(opts) && opts.length) {
          const a = el('div', 'acts ' + (opts.length === 2 ? 'two' : 'one'));
          for (const o of opts) {
            const b = el('button', 'a-go', o);
            b.type = 'button';
            b.addEventListener('click', () => reply(f, o));
            a.appendChild(b);
          }
          c.appendChild(a);
        } else {
          c.appendChild(el('div', 'notice err', 'لم تُرسل القاعدة خيارات الردّ (reply_options).'));
        }
      }
      // رأي حرّ (needs_note) — نصّ يكتبه وليّ الأمر ويرجع في النموذج
      if (f.needs_note) {
        const a = el('div', 'acts one');
        const b = el('button', 'a-go', 'اكتب رأيك');
        b.type = 'button';
        b.addEventListener('click', () => note(f));
        a.appendChild(b);
        c.appendChild(a);
      }
      box.appendChild(c);
    }
  }

  async function note(f) {
    $('noteWhat').textContent = f.title_ar || '';
    $('noteText').value = '';
    $('noteOk').disabled = true;
    if (await ask($('noteDlg')) !== 'ok') return;
    const { error } = await M.rpc('v2_guardian_form_note',
      { p_inbox: f.inbox_id, p_note: $('noteText').value.trim() }, 'رأي وليّ الأمر');
    if (error) { toast('لم يُرسل رأيك:\n' + errText(error)); return; }
    toast('أُرسل رأيك.', true);
    await refresh();
  }

  async function markRead(f) {
    if (f.read_at || ui.read.has(f.inbox_id)) return;
    ui.read.add(f.inbox_id);
    const { error } = await M.rpc('v2_guardian_form_read', { p_inbox: f.inbox_id }, 'وسم نموذج مقروءاً');
    if (error) { ui.read.delete(f.inbox_id); toast('لم يُوسم مقروءاً:\n' + errText(error)); return; }
    const card = [...document.querySelectorAll('.gform')][ui.forms.indexOf(f)];
    if (card) card.classList.remove('unread');
  }

  async function sign(f, signed) {
    let reason = null;
    if (!signed) {
      $('refWhat').textContent = f.title_ar || '';
      $('refReason').value = '';
      $('refOk').disabled = true;
      if (await ask($('refuseDlg')) !== 'ok') return;
      reason = $('refReason').value.trim();
    }
    const { error } = await M.rpc('v2_form_sign',
      { p_entry: f.entry_id, p_signer: SIGNER, p_signed: signed, p_refuse_reason: reason }, 'توقيع وليّ الأمر');
    if (error) { toast('لم يُسجَّل توقيعك:\n' + errText(error)); return; }
    toast(signed ? 'سُجّل إقرارك.' : 'سُجّل امتناعك وسببه.', true);
    await refresh();
  }

  async function reply(f, choice) {
    $('repWhat').textContent = choice;
    $('repNote').value = '';
    if (await ask($('replyDlg')) !== 'ok') return;
    const { error } = await M.rpc('v2_guardian_form_reply',
      { p_inbox: f.inbox_id, p_reply: choice, p_note: $('repNote').value.trim() || null }, 'ردّ وليّ الأمر');
    if (error) { toast('لم يُرسل ردّك:\n' + errText(error)); return; }
    toast('أُرسل ردّك: ' + choice, true);
    await refresh();
  }

  async function refresh() {
    showLoadErr('');
    const { data, error } = await M.rpc('v2_guardian_forms', undefined, 'نماذج وليّ الأمر');
    if (error) { showLoadErr('تعذّر جلب النماذج: ' + errText(error)); ui.forms = []; render(); return; }
    ui.forms = data || [];
    render();
  }

  $('noteText').addEventListener('input', () => { $('noteOk').disabled = $('noteText').value.trim() === ''; });
  $('refReason').addEventListener('input', () => { $('refOk').disabled = $('refReason').value.trim() === ''; });
  $('toast').addEventListener('click', () => { $('toast').hidden = true; });
  $('logout').addEventListener('click', M.signOut);

  (async () => {
    const { data: sess } = await M.sb.auth.getSession();
    if (!sess.session) { location.replace('./'); return; }
    const { data: g, error } = await M.rpc('v2_guardian_me', undefined, 'حساب وليّ الأمر');
    if (error) { showLoadErr('تعذّر جلب حسابك: ' + errText(error)); return; }
    if (!g) { showLoadErr('حسابك غير مربوط بوليّ أمر في مؤيّد.'); return; }
    $('gWho').textContent = g.name || '';
    const kids = $('kids');
    for (const k of g.children || []) {
      kids.appendChild(el('div', 'meta', (k.name || '') + ' — ' + [k.class_ar, k.school].filter(Boolean).join(' · ')));
    }
    $('gView').hidden = false;
    await refresh();
  })();
})();

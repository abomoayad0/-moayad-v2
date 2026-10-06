// مؤيّد · ما عليّ — viewK في المحاكي (شاشةُ المكلَّف): لكلّ منسوبٍ ما أُسند إليه وحدَه.
// ① إثباتُ مشاركة طالب: ما أُحيل إليك إقرارُه (v2_entries_pending · delegated_to_me) ⇒ v2_entry_verdict
// ② رأيٌ مطلوبٌ منك · ③ كُلّفتَ بحصر سلوكيّات طالب: لم يُبنيا في المحرّك
// ④ ما عليّ من اللجان: v2_my_committee_tasks ⇒ v2_committee_task_done
// ترى هذا الجزءَ وحدَه: لا ملفَّ طالبٍ ولا دراسةَ حالة.
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { $, el, errText, showLoadErr } = M;

  async function refresh() {
    if (!M.state.school) return;
    showLoadErr('');
    V.renderRole();
    renderOff();
    await Promise.all([loadDelegated(), loadCommittee()]);
  }

  async function loadDelegated() {
    const { data, error } = await M.rpc('v2_entries_pending', { p_school: M.state.school }, 'ما أُحيل إليك');
    const box = $('dlg');
    box.textContent = '';
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    // ما أُحيل إليك وحدَه — لا ما تقيمه ولا ما يراه المالك
    const mine = (data || []).filter((x) => x.delegated_to_me === true);
    if (!mine.length) { box.appendChild(el('p', 'rs-meta', 'لم يُحَل إليك إقرارُ مشاركة.')); return; }
    for (const x of mine) box.appendChild(V.verdictCard(x, { onDone: loadDelegated }));
    V.arabize(box);
  }

  async function loadCommittee() {
    const { data, error } = await M.rpc('v2_my_committee_tasks', { p_school: M.state.school }, 'ما عليّ من اللجان');
    const box = $('ctasks');
    box.textContent = '';
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    const list = data || [];
    if (!list.length) { box.appendChild(el('p', 'rs-meta', 'لا قرارَ مسندًا إليك لم يُنفَّذ.')); return; }
    for (const t of list) box.appendChild(V.committeeTask(t, loadCommittee));
  }

  function renderOff() {
    const box = $('offCards');
    box.textContent = '';
    box.append(V.offCard('رأيٌ مطلوبٌ منك', 'رأيُ المعلّم في خطّة تعديل السلوك — نموذج ٣ · القسمُ السادس'),
      V.offCard('كُلّفتَ بحصر سلوكيّات طالب', 'الإجراءُ الثاني — من الوكيل'));
  }

  M.start({ screen: 'mukallaf', onChange: () => refresh() });
})();

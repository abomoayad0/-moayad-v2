// مؤيّد · شاشةُ جدول الحصص — أبوابُها الخمسة على نموذج المحاكي، وأدواتُها هي أدواتُ اللوحة نفسُها (jadwal.js).
// الشبكة · النصاب · خطّةُ المواد · التخصّصات · التوزيعُ الآليّ. والمفتاحُ manage_settings: المدير والوكيلان ووكيلُ الشؤون التعليميّة.
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const J = window.MoayadJadwal;
  const { $ } = M;

  const DOORS = [
    ['grid', 'الجدول', 'شبكةُ الأيّام والحصص لمعلّمٍ أو لفصل — والتضاربُ يُعرض قبل الحفظ ولا يُتجاوز إلا بإقرار.', J.timetableTool],
    ['quota', 'النصاب', 'نصابُ الحصص لكلّ صفة.', J.quotaTool],
    ['plan', 'خطّةُ المواد', 'حصصُ كلّ مادّةٍ في كلّ صفّ.', J.planTool],
    ['subjects', 'التخصّصات', 'ما يُتقنه كلُّ معلّمٍ من الموادّ.', J.subjectsTool],
    ['drafts', 'التوزيعُ الآليّ', 'النظامُ يقترح والإنسانُ يقرّ بكتابة «أقرّ».', J.draftsTool],
  ];
  let door = 'grid';

  function render() {
    V.renderRole();
    V.pick($('doors'), DOORS.map((d) => [d[0], d[1]]), door, (v) => { door = v; render(); });
    const d = DOORS.find((x) => x[0] === door);
    $('doorTitle').textContent = d[1];
    $('doorNote').textContent = d[2];
    d[3]($('doorBox'));
  }

  M.start({ screen: 'jadwal', onChange: () => render() });
})();

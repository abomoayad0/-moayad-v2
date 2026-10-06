// مؤيّد · شاشةُ الإنابة في الصفات — على نموذج المحاكي، وأداتُها أداةُ اللوحة نفسُها (inaba.js).
// v2_delegations_board · v2_delegate_add · v2_delegate_revoke — وسطرُ الإنابة في الرأس من v2_my_acting (common.js).
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { $ } = M;

  M.start({
    screen: 'inaba',
    onChange: () => { V.renderRole(); return window.MoayadInaba.delegationsTool($('inabaBox')); },
  });
})();

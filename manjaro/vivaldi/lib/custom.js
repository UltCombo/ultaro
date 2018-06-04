(async () => {
  'use strict';

  const delay = ms => new Promise(resolve => setTimeout(resolve, ms));

  let addressBar;

  while (!(addressBar = document.querySelector('.vivaldi-addressfield'))) {
    await delay(20);
  }

  const focusAddressBar = () => addressBar.focus();

  window.addEventListener('keydown', ({ ctrlKey, key }) => {
    if (ctrlKey && key === 't') {
      focusAddressBar();
    }
  });

  // On new window.
  setTimeout(() => {
    if (!addressBar.value) {
      focusAddressBar();
    }
  }, 10);
})();

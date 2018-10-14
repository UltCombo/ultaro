(async () => {
  'use strict';

  const $ = (...args) => document.querySelector(...args);
  const delay = ms => new Promise(resolve => setTimeout(resolve, ms));

  let addressBar;
  let webpageStack;

  while (!(addressBar = $('.vivaldi-addressfield'))) {
    await delay(20);
  }

  while (!(webpageStack = $('#webpage-stack'))) {
    await delay(20);
  }

  const focusAddressBarOnNewTab = () => setTimeout(() => {
    if (!addressBar.value) {
      addressBar.focus();
    }
  }, 10);

  new MutationObserver((mutations) => {
    for (const { addedNodes } of mutations) {
      if (addedNodes.length && addedNodes[0].classList.contains('active')) {
        focusAddressBarOnNewTab();
        return;
      }
    }
  }).observe(webpageStack, { childList: true });

  // On new window.
  focusAddressBarOnNewTab();
})();

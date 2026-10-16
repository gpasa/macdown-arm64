(function () {
  var root = document.documentElement;
  root.classList.add('mpd-sticky');

  function opaque(color) {
    return color && color !== 'transparent' && !/rgba\(.*,\s*0\)$/.test(color);
  }

  function update() {
    var body = document.body;
    if (!body)
      return;
    var bs = getComputedStyle(body);
    var bg = opaque(bs.backgroundColor) ? bs.backgroundColor
           : getComputedStyle(root).backgroundColor;
    root.style.setProperty('--mpd-sticky-bg', opaque(bg) ? bg : 'white');
    root.style.setProperty('--mpd-pad-left', bs.paddingLeft);
    root.style.setProperty('--mpd-pad-right', bs.paddingRight);

    var h1 = document.querySelector('h1');
    var h2 = document.querySelector('h2');
    root.style.setProperty('--mpd-h1-height', (h1 ? h1.offsetHeight : 0) + 'px');
    root.style.setProperty('--mpd-h2-height', (h2 ? h2.offsetHeight : 0) + 'px');
  }

  if (document.readyState === 'loading')
    document.addEventListener('DOMContentLoaded', update);
  else
    update();
  window.addEventListener('load', update);
  window.addEventListener('resize', update);
})();

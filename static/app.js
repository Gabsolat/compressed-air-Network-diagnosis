/* Compressed-air network diagnosis: theme, live pressure profile, form guidance, report navigation */
(function () {
  'use strict';
  var $ = function (s, r) { return (r || document).querySelector(s); };
  var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };
  var NS = 'http://www.w3.org/2000/svg';
  var reduce = window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches;

  function isNum(x) { return typeof x === 'number' && isFinite(x); }
  function svg(name, attrs, parent, text) {
    var e = document.createElementNS(NS, name);
    for (var k in attrs) { e.setAttribute(k, attrs[k]); }
    if (text !== undefined) { e.textContent = text; }
    if (parent) { parent.appendChild(e); }
    return e;
  }

  /* ---------- theme ---------- */
  var tbtn = $('#theme-toggle');
  function paintToggle() {
    if (!tbtn) { return; }
    var dark = document.documentElement.dataset.theme === 'dark';
    tbtn.textContent = dark ? 'Light mode' : 'Dark mode';
    tbtn.setAttribute('aria-pressed', dark ? 'true' : 'false');
  }
  if (tbtn) {
    paintToggle();
    tbtn.addEventListener('click', function () {
      var next = document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark';
      document.documentElement.dataset.theme = next;
      try { localStorage.setItem('krr-theme', next); } catch (e) { /* ignore */ }
      paintToggle();
    });
  }

  /* ---------- pressure profile ---------- */
  var STATIONS = ['Compressor', 'Receiver', 'After dryer', 'After filter', 'Header end', 'Point of use'];
  var SECTIONS = ['', 'between the compressor and the receiver', 'across the dryer', 'across the filter',
                  'along the header', 'through the regulator and branch line'];

  function profileData(v) {
    var m = isNum(v.m_in) ? v.m_in : (isNum(v.m_use) ? v.m_use / 0.92 : 12);
    var K = (m / 12) * (m / 12);
    var ref = [7.8, 7.7];
    ref.push(ref[1] - 0.20 * K);
    ref.push(ref[2] - 0.15 * K);
    ref.push(ref[3] - 0.25 * K);
    ref.push(Math.min(6.45, ref[4] - 0.12));
    var prec = isNum(v.p_rec) ? v.p_rec : (isNum(v.p_rec_b) ? v.p_rec_b : null);
    var meas = [isNum(v.p_dis) ? v.p_dis : null, prec, null, null,
                isNum(v.p_hdr) ? v.p_hdr : null, isNum(v.p_use) ? v.p_use : null];
    if (prec !== null && isNum(v.dp_dryer)) { meas[2] = prec - v.dp_dryer; }
    if (meas[2] !== null && isNum(v.dp_filter)) { meas[3] = meas[2] - v.dp_filter; }
    return { ref: ref, meas: meas, setpoint: isNum(v.p_set) ? v.p_set : null };
  }

  function drawProfile(host, values, noteEl, animate) {
    var d = profileData(values);
    var W = 640, H = 300, L = 56, R = 22, T = 26, B = 58;
    var all = d.ref.slice();
    d.meas.forEach(function (x) { if (x !== null) { all.push(x); } });
    if (d.setpoint !== null) { all.push(d.setpoint); }
    var lo = Math.floor((Math.min.apply(null, all) - 0.3) * 2) / 2;
    var hi = Math.ceil((Math.max.apply(null, all) + 0.2) * 2) / 2;
    if (hi - lo < 2) { lo = hi - 2; }
    var X = function (i) { return L + i * (W - L - R) / 5; };
    var Y = function (p) { return T + (hi - p) * (H - T - B) / (hi - lo); };

    host.textContent = '';
    var s = svg('svg', { viewBox: '0 0 ' + W + ' ' + H, role: 'img' }, host);
    var step = (hi - lo) > 4 ? 1 : 0.5;
    for (var t = Math.ceil(lo / step) * step; t <= hi + 1e-9; t += step) {
      svg('line', { x1: L, x2: W - R, y1: Y(t), y2: Y(t), 'class': 'gl' }, s);
      svg('text', { x: L - 8, y: Y(t) + 4, 'text-anchor': 'end' }, s, t.toFixed(1));
    }
    svg('line', { x1: L, x2: L, y1: T, y2: H - B, 'class': 'axis' }, s);
    svg('line', { x1: L, x2: W - R, y1: H - B, y2: H - B, 'class': 'axis' }, s);
    var yl = svg('text', { x: 14, y: (T + H - B) / 2, 'text-anchor': 'middle',
                           transform: 'rotate(-90 14 ' + ((T + H - B) / 2) + ')' }, s, 'Pressure, bar(g)');
    yl.setAttribute('class', '');
    STATIONS.forEach(function (name, i) {
      var has = d.meas[i] !== null;
      svg('text', { x: X(i), y: H - B + 20, 'text-anchor': 'middle', 'class': has ? '' : 'off' }, s, name);
      if (!has) { svg('text', { x: X(i), y: H - B + 36, 'text-anchor': 'middle', 'class': 'off' }, s, 'no reading'); }
    });
    if (d.setpoint !== null) {
      svg('line', { x1: L, x2: W - R, y1: Y(d.setpoint), y2: Y(d.setpoint), 'class': 'setp' }, s);
      svg('text', { x: W - R - 4, y: Y(d.setpoint) - 6, 'text-anchor': 'end' }, s,
          'Regulator set-point ' + d.setpoint.toFixed(2));
    }
    var rp = d.ref.map(function (p, i) { return (i ? 'L' : 'M') + X(i) + ' ' + Y(p); }).join(' ');
    svg('path', { d: rp, 'class': 'ref' }, s);
    d.ref.forEach(function (p, i) { svg('circle', { cx: X(i), cy: Y(p), r: 4, 'class': 'refpt' }, s); });

    var runs = [], cur = [];
    d.meas.forEach(function (p, i) {
      if (p === null) { if (cur.length) { runs.push(cur); cur = []; } } else { cur.push(i); }
    });
    if (cur.length) { runs.push(cur); }
    runs.forEach(function (run) {
      if (run.length > 1) {
        var pd = run.map(function (i, k) { return (k ? 'L' : 'M') + X(i) + ' ' + Y(d.meas[i]); }).join(' ');
        svg('path', { d: pd, pathLength: 1, 'class': 'line' }, s);
      }
    });
    var worst = null;
    d.meas.forEach(function (p, i) {
      if (p === null) { return; }
      var hot = false;
      if (i > 0 && d.meas[i - 1] !== null) {
        var drop = d.meas[i - 1] - p, rdrop = d.ref[i - 1] - d.ref[i];
        var excess = drop - rdrop;
        hot = excess > 0.10 && drop > 1.8 * rdrop;
        svg('text', { x: (X(i) + X(i - 1)) / 2, y: Math.min(Y(p), Y(d.meas[i - 1])) - 10, 'text-anchor': 'middle',
                      'class': 'drop' + (hot ? ' hot' : '') }, s, (drop >= 0 ? '\u2212' : '+') + Math.abs(drop).toFixed(2));
        if (hot && (worst === null || excess > worst.excess)) {
          worst = { i: i, drop: drop, rdrop: rdrop, excess: excess };
        }
      }
      svg('circle', { cx: X(i), cy: Y(p), r: 5.5, 'class': 'pt' + (hot ? ' hot' : '') }, s);
    });
    svg('line', { x1: L + 6, x2: L + 34, y1: 11, y2: 11, 'class': 'ref' }, s);
    svg('text', { x: L + 40, y: 15, 'class': 'legend' }, s, 'Healthy reference at this flow');
    svg('line', { x1: L + 236, x2: L + 264, y1: 11, y2: 11, 'class': 'line' }, s).style.strokeDasharray = 'none';
    svg('text', { x: L + 270, y: 15, 'class': 'legend' }, s, 'Your readings');

    var count = d.meas.filter(function (p) { return p !== null; }).length;
    host.classList.toggle('animate', !!animate && !reduce);
    s.setAttribute('aria-label', 'Pressure profile with readings at ' + count + ' of 6 stations. ' +
      (worst ? 'The largest excess pressure loss is ' + SECTIONS[worst.i] + '.' : 'No section loses abnormal pressure.'));
    if (noteEl) {
      if (count < 2) {
        noteEl.textContent = 'Enter two or more pressures along the network and the profile draws itself. The dashed line shows a healthy station at the same flow.';
      } else if (worst) {
        noteEl.textContent = 'The air loses ' + worst.drop.toFixed(2) + ' bar ' + SECTIONS[worst.i] +
          ', against about ' + worst.rdrop.toFixed(2) + ' bar when healthy.';
      } else {
        noteEl.textContent = 'No section loses more pressure than a healthy network at this flow would.';
      }
    }
  }

  function parseQuery(q) {
    var out = {};
    (q || '').split('&').forEach(function (kv) {
      var p = kv.split('=');
      if (p[0] && p[1] !== undefined && p[1] !== '') { var n = parseFloat(p[1]); if (isNum(n)) { out[p[0]] = n; } }
    });
    return out;
  }

  /* ---------- diagnosis form ---------- */
  var form = $('#diag');
  var profile = $('#profile');
  var note = $('#profile-note');

  if (form) {
    var inputs = $$('input[type="number"]', form);
    var TOTAL = inputs.length;
    var CAPS = [
      { n: 'Leakage',
        ok: function (h) { return (h('m_in') && h('m_use')) || (h('l_a') && h('cyc')); },
        part: function (h) { return h('m_in') || h('m_use') || h('l_a'); },
        need: 'Needs air produced and metered use, or ultrasonic level with cycling.' },
      { n: 'Compressor performance',
        ok: function (h) { return h('m_in') && h('load'); },
        part: function (h) { return h('m_in') || h('load') || h('p_sh'); },
        need: 'Needs air produced and the loaded fraction. Power, temperature and vibration sharpen it.' },
      { n: 'Filter restriction',
        ok: function (h) { return h('dp_filter') && (h('m_in') || h('m_use')); },
        part: function (h) { return h('dp_filter'); },
        need: 'Needs the filter pressure drop and a flow reading.' },
      { n: 'Dryer and air quality',
        ok: function (h) { return h('t_dew') || (h('dp_dryer') && (h('m_in') || h('m_use'))); },
        part: function (h) { return h('dp_dryer'); },
        need: 'Needs the dew point, or the dryer pressure drop with a flow reading.' },
      { n: 'Receiver and drain',
        ok: function (h) { return h('cyc') && h('c_water'); },
        part: function (h) { return h('cyc') || h('c_water'); },
        need: 'Needs cycles per hour and the drain flow.' },
      { n: 'Distribution restriction',
        ok: function (h) { return h('p_hdr') && h('dp_dryer') && h('dp_filter') && (h('p_rec') || h('p_rec_b') || h('p_dis')) && (h('m_in') || h('m_use')); },
        part: function (h) { return h('p_hdr') || h('p_rec') || h('p_dis'); },
        need: 'Needs header-end pressure, dryer and filter drops, receiver pressure and a flow reading.' },
      { n: 'Regulator',
        ok: function (h) { return h('p_set') && h('p_use'); },
        part: function (h) { return h('p_set') || h('p_use'); },
        need: 'Needs the set-point and the pressure at the point of use. Header pressure separates a supply problem.' },
      { n: 'Instrument faults',
        ok: function (h) { return (h('p_rec') && h('p_rec_b')) || (h('m_in') && h('m_use') && h('l_a')); },
        part: function (h) { return h('p_rec') || h('p_rec_b') || h('m_use'); },
        need: 'Needs two receiver sensors, or flows with an ultrasonic reading to cross-check.' }
    ];
    var capsEl = $('#caps');
    var countEl = $('#count');
    var barEl = $('#count-bar');
    var msg = $('#form-msg');

    var valid = function (inp) {
      if (inp.value === '') { return true; }
      var n = parseFloat(inp.value);
      if (!isNum(n)) { return false; }
      var min = inp.getAttribute('min'), max = inp.getAttribute('max');
      if (min !== null && n < parseFloat(min)) { return false; }
      if (max !== null && n > parseFloat(max)) { return false; }
      return true;
    };
    var values = function () {
      var v = {};
      inputs.forEach(function (i) { if (i.value !== '' && valid(i)) { v[i.name] = parseFloat(i.value); } });
      return v;
    };
    var update = function () {
      var v = values();
      var h = function (k) { return isNum(v[k]); };
      var n = Object.keys(v).length;
      if (countEl) { countEl.textContent = n; }
      if (barEl) { barEl.style.width = (100 * n / TOTAL) + '%'; }
      if (capsEl) {
        capsEl.textContent = '';
        CAPS.forEach(function (c) {
          var st = c.ok(h) ? 'ready' : (c.part(h) ? 'partial' : 'none');
          var li = document.createElement('li');
          li.className = st;
          var dot = document.createElement('span'); dot.className = 'dot';
          var box = document.createElement('div');
          var nm = document.createElement('div'); nm.className = 'name'; nm.textContent = c.n;
          var sd = document.createElement('div'); sd.className = 'state';
          sd.textContent = st === 'ready' ? 'Can be assessed' : c.need;
          box.appendChild(nm); box.appendChild(sd);
          li.appendChild(dot); li.appendChild(box);
          capsEl.appendChild(li);
        });
      }
      inputs.forEach(function (i) { i.classList.toggle('invalid', !valid(i)); });
      if (profile) { drawProfile(profile, v, note, false); }
    };
    inputs.forEach(function (i) { i.addEventListener('input', function () { if (msg) { msg.textContent = ''; } update(); }); });

    $$('.example').forEach(function (b) {
      b.addEventListener('click', function () {
        var vals = parseQuery(b.getAttribute('data-obs'));
        inputs.forEach(function (i) { i.value = isNum(vals[i.name]) ? vals[i.name] : ''; });
        $$('.example').forEach(function (x) { x.setAttribute('aria-pressed', x === b ? 'true' : 'false'); });
        update();
      });
    });
    var clear = $('#clear');
    if (clear) {
      clear.addEventListener('click', function () {
        inputs.forEach(function (i) { i.value = ''; });
        $$('.example').forEach(function (x) { x.setAttribute('aria-pressed', 'false'); });
        if (msg) { msg.textContent = ''; }
        update();
      });
    }
    form.addEventListener('submit', function (e) {
      var n = Object.keys(values()).length;
      var bad = inputs.filter(function (i) { return !valid(i); });
      if (bad.length) {
        e.preventDefault(); if (msg) { msg.textContent = 'Some values are not valid numbers or are out of range. Check the highlighted fields.'; }
        bad[0].focus(); return;
      }
      if (n < 2) {
        e.preventDefault(); if (msg) { msg.textContent = 'Enter at least two readings so the checks have something to compare.'; }
        inputs[0].focus(); return;
      }
      inputs.forEach(function (i) { if (i.value === '') { i.disabled = true; } });
      var ov = document.createElement('div');
      ov.className = 'overlay show'; ov.setAttribute('role', 'status');
      ov.innerHTML = '<div><div class="spinner"></div><div>Running the reasoning engine</div></div>';
      document.body.appendChild(ov);
    });
    window.addEventListener('pageshow', function () {
      inputs.forEach(function (i) { i.disabled = false; });
      var o = $('.overlay'); if (o) { o.remove(); }
      update();
    });
    update();
  } else if (profile && profile.getAttribute('data-obs')) {
    drawProfile(profile, parseQuery(profile.getAttribute('data-obs')), note, true);
  }

  /* ---------- report: table of contents highlight, print ---------- */
  var links = $$('.toc a');
  if (links.length && 'IntersectionObserver' in window) {
    var map = {};
    links.forEach(function (a) { map[a.getAttribute('href').slice(1)] = a; });
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        if (en.isIntersecting) {
          links.forEach(function (a) { a.classList.remove('active'); });
          if (map[en.target.id]) { map[en.target.id].classList.add('active'); }
        }
      });
    }, { rootMargin: '-20% 0px -70% 0px' });
    $$('.step').forEach(function (s) { io.observe(s); });
  }
  var pr = $('#print');
  if (pr) { pr.addEventListener('click', function () { window.print(); }); }
})();

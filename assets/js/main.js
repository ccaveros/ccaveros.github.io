// Language preference — apply immediately to prevent flash
(function () {
  var saved = localStorage.getItem('lang');
  if (saved === 'es' || (saved === null && (navigator.language || '').toLowerCase().startsWith('es'))) {
    document.body.classList.add('lang-es');
    document.documentElement.lang = 'es';
  }
})();

// Dark mode — apply saved preference immediately to prevent flash
(function () {
  var saved = localStorage.getItem('dark-mode');
  if (saved === 'true' || (saved === null && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
    document.body.classList.add('dark-mode');
  }
})();

// Mobile nav toggle
document.addEventListener('DOMContentLoaded', function () {
  var toggle = document.querySelector('.nav-toggle');
  var links = document.querySelector('.nav-links');

  if (toggle && links) {
    toggle.addEventListener('click', function () {
      links.classList.toggle('open');
    });

    // Close menu when a link is clicked
    links.querySelectorAll('a').forEach(function (link) {
      link.addEventListener('click', function () {
        links.classList.remove('open');
      });
    });
  }

  // Dark mode toggle
  var darkToggle = document.querySelector('.dark-mode-toggle');
  if (darkToggle) {
    darkToggle.addEventListener('click', function () {
      document.body.classList.toggle('dark-mode');
      var isDark = document.body.classList.contains('dark-mode');
      localStorage.setItem('dark-mode', isDark);
    });
  }

  // Language toggle
  var langToggle = document.querySelector('.lang-toggle');
  if (langToggle) {
    langToggle.addEventListener('click', function () {
      var isSpanish = document.body.classList.toggle('lang-es');
      document.documentElement.lang = isSpanish ? 'es' : 'en';
      localStorage.setItem('lang', isSpanish ? 'es' : 'en');
    });
  }
});

// Expandable publication cards
function togglePub(header) {
  var details = header.parentElement.querySelector('.pub-details');
  var btn = header.querySelector('.pub-toggle');
  if (details) {
    details.classList.toggle('open');
    btn.classList.toggle('open');
  }
}

// Research interests popover
(function () {
  var tagPapers = {
    'Peace': [
      { title: 'Civil Society and the Local Dynamics of Peacebuilding', href: 'research.html' },
      { title: 'The Demand for Rebel Rules', href: 'research.html' }
    ],
    'Civil Society': [
      { title: 'Civil Society and the Local Dynamics of Peacebuilding', href: 'research.html' }
    ],
    'Dispute Resolution': [
      { title: 'Civil Society and the Local Dynamics of Peacebuilding', href: 'research.html' },
      { title: 'The Demand for Rebel Rules', href: 'research.html' }
    ],
    'Multi-Method Research': [
      { title: 'Civil Society and the Local Dynamics of Peacebuilding', href: 'research.html' }
    ],
    'Colombia': [
      { title: 'Elections under Contested Authority', href: 'research.html' }
    ]
  };

  var popover = document.createElement('div');
  popover.id = 'interest-popover';
  popover.innerHTML = '<p class="popover-label"></p><ul class="popover-papers"></ul>';
  document.body.appendChild(popover);

  var hideTimer = null;

  function showPopover(tag) {
    var key = tag.getAttribute('data-interest');
    var papers = tagPapers[key];
    if (!papers || papers.length === 0) return;

    clearTimeout(hideTimer);

    var isEs = document.body.classList.contains('lang-es');
    popover.querySelector('.popover-label').textContent = isEs ? 'Publicaciones relacionadas' : 'Related work';

    var list = popover.querySelector('.popover-papers');
    list.innerHTML = papers.map(function (p) {
      return '<li><a href="' + p.href + '">' + p.title + '</a></li>';
    }).join('');

    var rect = tag.getBoundingClientRect();
    var top = rect.bottom + window.scrollY + 6;
    var left = rect.left + window.scrollX;
    var popoverWidth = 260;
    if (left + popoverWidth > window.innerWidth - 16) {
      left = Math.max(16, window.innerWidth - popoverWidth - 16);
    }

    popover.style.top = top + 'px';
    popover.style.left = left + 'px';
    popover.classList.add('visible');
  }

  function scheduleHide() {
    hideTimer = setTimeout(function () {
      popover.classList.remove('visible');
    }, 150);
  }

  function initPopover() {
    document.querySelectorAll('.interests li[data-interest]').forEach(function (tag) {
      var key = tag.getAttribute('data-interest');
      if (tagPapers[key] && tagPapers[key].length > 0) {
        tag.style.cursor = 'pointer';
        tag.addEventListener('mouseenter', function () { showPopover(tag); });
        tag.addEventListener('mouseleave', scheduleHide);
      }
    });
    popover.addEventListener('mouseenter', function () { clearTimeout(hideTimer); });
    popover.addEventListener('mouseleave', scheduleHide);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initPopover);
  } else {
    initPopover();
  }
})();

// Expand/Collapse all abstracts
function toggleAllPubs(btn) {
  var details = document.querySelectorAll('.pub-details');
  var toggles = document.querySelectorAll('.pub-toggle');
  var expanding = btn.getAttribute('data-state') !== 'expanded';

  details.forEach(function (d) {
    d.classList[expanding ? 'add' : 'remove']('open');
  });

  toggles.forEach(function (t) {
    t.classList[expanding ? 'add' : 'remove']('open');
  });

  btn.setAttribute('data-state', expanding ? 'expanded' : 'collapsed');
}

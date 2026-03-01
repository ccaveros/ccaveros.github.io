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

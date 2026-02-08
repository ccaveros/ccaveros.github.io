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
  var expanding = btn.textContent.trim() === 'Expand All';

  details.forEach(function (d) {
    if (expanding) {
      d.classList.add('open');
    } else {
      d.classList.remove('open');
    }
  });

  toggles.forEach(function (t) {
    if (expanding) {
      t.classList.add('open');
    } else {
      t.classList.remove('open');
    }
  });

  btn.textContent = expanding ? 'Collapse All' : 'Expand All';
}

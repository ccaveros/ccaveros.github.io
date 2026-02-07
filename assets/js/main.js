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

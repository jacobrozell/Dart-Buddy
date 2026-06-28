(function () {
  var page = document.body.dataset.page;
  var locale = document.body.dataset.locale || "en";
  var select = document.getElementById("lang-select");
  if (!select || !page) return;

  var suffix = page === "index" ? "index.html" : page + ".html";
  var enHref = locale === "de" ? "../" + suffix : suffix;
  var deHref = locale === "de" ? suffix : "de/" + suffix;

  [
    { code: "en", label: "English", href: enHref },
    { code: "de", label: "Deutsch", href: deHref },
  ].forEach(function (opt) {
    var option = document.createElement("option");
    option.value = opt.href;
    option.textContent = opt.label;
    if (opt.code === locale) option.selected = true;
    select.appendChild(option);
  });

  select.addEventListener("change", function () {
    if (select.value) window.location.href = select.value;
  });
})();

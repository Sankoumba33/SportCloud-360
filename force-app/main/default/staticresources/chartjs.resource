/* chartjs bootstrap loader for SC360.
 * For production packaging, replace by vendored chart.umd.min.js content.
 */
(function () {
  if (window.Chart) {
    return;
  }
  var script = document.createElement("script");
  script.src = "https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js";
  script.async = true;
  document.head.appendChild(script);
})();

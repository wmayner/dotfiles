// Draws the SVG parts of summary figures (see summary.css). Load it at the end of <body>:
//   <script src="../summary.js"></script>
// 1. Icons: any element with data-icon="model | magnifier | check | cross | arrow | arrow-dashed" gets an inline SVG.
// 2. Networks: <svg class="net" width="220" height="200" ...> with these attributes (units are "layer.index", from 0):
//    data-layers="3,5,4,2"      units per layer, drawn left (input) to right (output)
//    data-on="1.1 1.3 2.2"      units in the circuit (accent); edges between "on" units in adjacent layers are accent
//    data-ablate="1 2"          layers whose units, other than "on" ones, are ablated (hollow, dashed, struck out)
//    data-dim="0"               layers whose units are greyed
//    data-dirs="1 2"            layers carrying a direction: an accent arrow across all the layer's units, which are tinted
//    data-broken="1 2"          directions drawn broken (dashed grey), e.g. after their neurons were ablated
//    data-r="13"                unit radius
(function () {
  const NS = "http://www.w3.org/2000/svg";
  const ICONS = {
    model: `<svg viewBox="0 0 100 100"><line x1="50" y1="6" x2="50" y2="20" stroke="currentColor" stroke-width="4"/>
      <circle cx="50" cy="7" r="6" class="antenna"/>
      <rect x="6" y="40" width="10" height="24" rx="4" class="ear"/><rect x="84" y="40" width="10" height="24" rx="4" class="ear"/>
      <rect x="14" y="20" width="72" height="66" rx="20" class="head" stroke="currentColor" stroke-width="4"/>
      <circle cx="37" cy="47" r="7.5" fill="currentColor"/><circle cx="63" cy="47" r="7.5" fill="currentColor"/>
      <path d="M36 67 Q50 77 64 67" fill="none" stroke="currentColor" stroke-width="4.5" stroke-linecap="round"/></svg>`,
    magnifier: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round">
      <circle cx="10" cy="10" r="6.5"/><line x1="15" y1="15" x2="21.5" y2="21.5"/></svg>`,
    check: `<svg viewBox="0 0 100 100"><path d="M18 52 L41 75 L84 27" fill="none" stroke="currentColor" stroke-width="15"
      stroke-linecap="round" stroke-linejoin="round"/></svg>`,
    cross: `<svg viewBox="0 0 100 100" stroke="currentColor" stroke-width="15" stroke-linecap="round">
      <line x1="18" y1="18" x2="82" y2="82"/><line x1="82" y1="18" x2="18" y2="82"/></svg>`,
    arrow: `<svg viewBox="0 0 90 28" width="100%" height="100%"><line x1="2" y1="14" x2="66" y2="14" stroke="currentColor"
      stroke-width="7"/><polygon points="62,1 89,14 62,27" fill="currentColor"/></svg>`,
    "arrow-dashed": `<svg viewBox="0 0 90 28" width="100%" height="100%"><line x1="2" y1="14" x2="66" y2="14" stroke="currentColor"
      stroke-width="5" stroke-dasharray="9 6"/><polygon points="62,3 89,14 62,25" fill="currentColor"/></svg>`,
  };
  document.querySelectorAll("[data-icon]").forEach(el => { el.insertAdjacentHTML("afterbegin", ICONS[el.dataset.icon] || ""); });

  const el = (tag, attrs, parent) => {
    const e = document.createElementNS(NS, tag);
    for (const k in attrs) e.setAttribute(k, attrs[k]);
    parent.appendChild(e); return e;
  };
  const list = s => (s || "").trim().split(/[\s,]+/).filter(Boolean);

  document.querySelectorAll("svg.net").forEach(svg => {
    const W = +svg.getAttribute("width"), H = +svg.getAttribute("height");
    const sizes = list(svg.dataset.layers).map(Number);
    const r = +(svg.dataset.r || 13), pad = r + 10;
    const on = new Set(list(svg.dataset.on)), ablate = new Set(list(svg.dataset.ablate));
    const dim = new Set(list(svg.dataset.dim)), dirs = new Set(list(svg.dataset.dirs)), broken = new Set(list(svg.dataset.broken));
    const xs = sizes.map((_, l) => sizes.length === 1 ? W / 2 : pad + l * (W - 2 * pad) / (sizes.length - 1));
    const pos = sizes.map((n, l) => {
      const gap = n === 1 ? 0 : Math.min((H - 2 * pad) / (n - 1), 3.4 * r), top = H / 2 - gap * (n - 1) / 2;
      return Array.from({ length: n }, (_, i) => [xs[l], top + i * gap]);
    });
    const edges = el("g", {}, svg), hot = el("g", {}, svg), units = el("g", {}, svg), over = el("g", {}, svg);
    for (let l = 0; l + 1 < sizes.length; l++)
      pos[l].forEach(([x1, y1], i) => pos[l + 1].forEach(([x2, y2], j) => {
        const lit = on.has(`${l}.${i}`) && on.has(`${l + 1}.${j}`);
        el("line", { x1, y1, x2, y2, class: lit ? "edge on" : "edge" }, lit ? hot : edges);
      }));
    pos.forEach((col, l) => col.forEach(([cx, cy], i) => {
      const id = `${l}.${i}`, cls = ["unit"];
      if (on.has(id)) cls.push("on");
      else if (ablate.has(`${l}`)) cls.push("ablated");
      else if (dirs.has(`${l}`) && !broken.has(`${l}`)) cls.push("part");
      else if (dim.has(`${l}`)) cls.push("dim");
      el("circle", { cx, cy, r, class: cls.join(" ") }, units);
      if (cls.includes("ablated")) {
        const d = r * 0.55;
        el("line", { x1: cx - d, y1: cy - d, x2: cx + d, y2: cy + d, class: "strike" }, over);
      }
    }));
    // A direction: one arrow drawn across all the layer's units, slanted so it reads as a vector, not a unit.
    dirs.forEach(ls => {
      const l = +ls, col = pos[l], b = broken.has(ls);
      const [x0, y0] = [xs[l] - r * 1.3, col[col.length - 1][1] + r * 0.6], [x1, y1] = [xs[l] + r * 1.3, col[0][1] - r * 0.6];
      const ang = Math.atan2(y1 - y0, x1 - x0), h = 16, back = [x1 - h * Math.cos(ang), y1 - h * Math.sin(ang)];
      el("line", { x1: x0, y1: y0, x2: back[0], y2: back[1], class: b ? "dir broken" : "dir" }, over);
      const px = Math.sin(ang) * h * 0.6, py = -Math.cos(ang) * h * 0.6;
      el("polygon", { points: `${x1},${y1} ${back[0] + px},${back[1] + py} ${back[0] - px},${back[1] - py}`,
                      class: b ? "dir-head broken" : "dir-head" }, over);
    });
  });
})();

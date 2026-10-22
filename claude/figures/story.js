// Draws the parts of a story figure (see story.css). Load it at the end of <body>, before summary.js:
//   <script src="../story.js"></script><script src="../summary.js"></script>
// 1. Cell stacks: <div class="cells" data-rows="8" data-cols="10" data-actor="a" data-read="3-5" data-shade="1">
//    data-actor     a | b | trained | untrained: the colour; light for unchanged layers, full for read layers
//    data-read      layers (1-based, "3-5" or "4") drawn at full colour
//    data-mark      cells drawn in the trained colour, as "layer.unit" pairs ("4.2 4.5"), e.g. units a mask keeps
//    data-shade     "1": each cell gets its own fixed shade, for an activation strip
// 2. Icon arrays: <div class="icons" data-n="96" data-per-row="24"></div>; add class "hollow" for held-out items.
// 3. The result chart: <div class="result" data-max="120" data-ref="4" data-ref-label="random guessing"
//    data-max-label="all 120"></div> filled from <script type="application/json" id="result"> holding
//    [{"name", "sub", "value", "lo", "hi", "kind": "trained" | "untrained", "gap": true for a group's first row,
//      "source": the results file and field the numbers came from (not drawn; it keeps every number traceable)}].
(function () {
  const COL = { a: ["--a-soft", "--a"], b: ["--b-soft", "--b"], trained: ["--trained-soft", "--trained"],
                untrained: ["--card", "--untrained"] };
  const range = s => { if (!s) return new Set(); const [a, b] = s.split("-").map(Number);
                       return new Set(Array.from({ length: (b || a) - a + 1 }, (_, i) => a + i)); };
  // A fixed shade per cell, so the image is the same on every render (no Math.random).
  const shade = (r, c, k) => [0.25, 0.55, 0.85, 0.4, 1, 0.3, 0.7][(r * 7 + c * 3 + k * 5 + r * c) % 7];

  document.querySelectorAll(".cells").forEach((g, k) => {
    const rows = +g.dataset.rows, cols = +g.dataset.cols, [soft, full] = COL[g.dataset.actor || "a"];
    const read = range(g.dataset.read), mark = new Set((g.dataset.mark || "").split(/\s+/).filter(Boolean));
    g.style.gridTemplateColumns = `repeat(${cols}, auto)`;
    for (let r = 1; r <= rows; r++) for (let c = 1; c <= cols; c++) {
      const i = document.createElement("i");
      if (mark.has(`${r}.${c}`)) i.style.background = "var(--trained)";
      else if (g.dataset.shade) { i.style.background = `var(${full})`; i.style.opacity = shade(r, c, k); }
      else i.style.background = `var(${read.has(r) ? full : soft})`;
      g.appendChild(i);
    }
  });

  document.querySelectorAll(".icons").forEach(g => {
    g.style.gridTemplateColumns = `repeat(${g.dataset.perRow || 24}, auto)`;
    for (let j = 0; j < +g.dataset.n; j++) g.appendChild(document.createElement("i"));
  });

  const data = document.getElementById("result"), box = document.querySelector(".result");
  if (data && box) {
    const max = +box.dataset.max, pct = v => `${(100 * v) / max}%`;
    const rows = JSON.parse(data.textContent);
    rows.forEach(d => {
      const row = document.createElement("div");
      row.className = "res-row" + (d.gap ? " gap" : "");
      row.innerHTML = `<div class="res-name"><b>${d.name}</b>${d.sub ? `<span class="sub">${d.sub}</span>` : ""}</div>
        <div class="res-track"><div class="res-bar" style="width:${pct(d.value)};background:var(--${d.kind})"></div>
        <div class="res-ci" style="left:${pct(d.lo)};width:calc(${pct(d.hi)} - ${pct(d.lo)})"></div>
        <div class="res-num" style="left:${pct(d.hi)}">${d.value}</div></div>`;
      box.appendChild(row);
    });
    // The reference line and the two words under the axis: the reference's name and the axis maximum.
    const foot = document.createElement("div");
    foot.className = "res-row";
    foot.innerHTML = `<div></div><div class="res-foot" style="margin-right:44px">
      <span style="left:${pct(+box.dataset.ref)}">${box.dataset.refLabel}</span>
      <span style="left:100%">${box.dataset.maxLabel}</span></div>`;
    box.appendChild(foot);
    // Two vertical lines over every row: the reference (dashed) and the axis maximum (light, solid).
    const track = box.querySelector(".res-track"), ref = document.createElement("div"), top = document.createElement("div");
    const place = () => {
      const x = v => `${track.offsetLeft + 1.5 + (track.clientWidth * v) / max}px`, y = `${box.querySelector(".res-row").offsetTop}px`;
      ref.style.left = x(+box.dataset.ref); top.style.left = x(max); ref.style.top = top.style.top = y;
    };
    ref.className = "res-ref"; top.className = "res-max"; box.append(ref, top); place(); window.addEventListener("resize", place);
  }
})();

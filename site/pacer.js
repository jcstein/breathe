(() => {
  const phaseSeconds = 5.5;
  const count = document.querySelector("[data-count]");
  const phase = document.querySelector("[data-phase]");
  if (!count || !phase) return;

  const reducedMotion = matchMedia("(prefers-reduced-motion: reduce)");
  const idleCount = count.textContent;
  const idlePhase = phase.textContent;
  let frame = 0;
  let start = 0;

  const tick = (now) => {
    const elapsed = ((now - start) / 1000) % (phaseSeconds * 2);
    const inhaling = elapsed < phaseSeconds;
    const remaining = phaseSeconds - (inhaling ? elapsed : elapsed - phaseSeconds);
    count.textContent = Math.max(remaining, 0.1).toFixed(1);
    phase.textContent = inhaling ? "breathe in" : "breathe out";
    frame = requestAnimationFrame(tick);
  };

  const sync = () => {
    cancelAnimationFrame(frame);
    const live = !reducedMotion.matches;
    document.documentElement.classList.toggle("pacer-live", live);
    if (live) {
      start = performance.now();
      frame = requestAnimationFrame(tick);
    } else {
      count.textContent = idleCount;
      phase.textContent = idlePhase;
    }
  };

  reducedMotion.addEventListener("change", sync);
  sync();
})();

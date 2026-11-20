(() => {
  const phaseSeconds = 5.5;
  const count = document.querySelector("[data-count]");
  const phase = document.querySelector("[data-phase]");
  if (!count || !phase || matchMedia("(prefers-reduced-motion: reduce)").matches) return;

  const start = performance.now();
  const tick = (now) => {
    const elapsed = ((now - start) / 1000) % (phaseSeconds * 2);
    const inhaling = elapsed < phaseSeconds;
    const remaining = phaseSeconds - (inhaling ? elapsed : elapsed - phaseSeconds);
    count.textContent = Math.max(remaining, 0.1).toFixed(1);
    phase.textContent = inhaling ? "breathe in" : "breathe out";
    requestAnimationFrame(tick);
  };
  document.documentElement.classList.add("pacer-live");
  requestAnimationFrame(tick);
})();

// SpecKit 生成的计算器逻辑
(function () {
  const display = document.getElementById("display");
  const state = { current: "0", previous: null, op: null, justEvaluated: false };

  function render() {
    display.textContent = formatNumber(state.current);
  }
  function formatNumber(s) {
    if (s === "Error") return s;
    const n = Number(s);
    if (!isFinite(n)) return "Error";
    // 简单千位分隔
    const [int, dec] = s.split(".");
    const intF = Number(int).toLocaleString("en-US", { maximumFractionDigits: 0 });
    return dec !== undefined ? `${intF}.${dec}` : intF;
  }
  function inputDigit(d) {
    if (state.justEvaluated) { state.current = "0"; state.justEvaluated = false; }
    state.current = state.current === "0" ? d : state.current + d;
  }
  function inputDot() {
    if (state.justEvaluated) { state.current = "0"; state.justEvaluated = false; }
    if (!state.current.includes(".")) state.current += ".";
  }
  function clearAll() { state.current = "0"; state.previous = null; state.op = null; }
  function sign() {
    if (state.current === "0") return;
    state.current = state.current.startsWith("-") ? state.current.slice(1) : "-" + state.current;
  }
  function percent() {
    const n = Number(state.current);
    state.current = String(n / 100);
  }
  function setOp(op) {
    if (state.op && state.previous !== null && !state.justEvaluated) {
      equals();
    }
    state.previous = state.current;
    state.op = op;
    state.current = "0";
  }
  function equals() {
    if (state.op === null || state.previous === null) return;
    const a = Number(state.previous);
    const b = Number(state.current);
    let r = 0;
    switch (state.op) {
      case "+": r = a + b; break;
      case "-": r = a - b; break;
      case "*": r = a * b; break;
      case "/": r = b === 0 ? NaN : a / b; break;
    }
    state.current = isFinite(r) ? String(Number(r.toFixed(10))) : "Error";
    state.previous = null;
    state.op = null;
    state.justEvaluated = true;
  }

  document.querySelector(".keys").addEventListener("click", (e) => {
    const t = e.target.closest("button");
    if (!t) return;
    const action = t.dataset.action;
    if (action === "digit") inputDigit(t.dataset.value);
    else if (action === "dot") inputDot();
    else if (action === "clear") clearAll();
    else if (action === "sign") sign();
    else if (action === "percent") percent();
    else if (action === "op") setOp(t.dataset.op);
    else if (action === "equals") equals();
    render();
  });

  // 键盘支持
  document.addEventListener("keydown", (e) => {
    if (/^[0-9]$/.test(e.key)) { inputDigit(e.key); render(); }
    else if (e.key === ".") { inputDot(); render(); }
    else if (["+", "-", "*", "/"].includes(e.key)) { setOp(e.key); render(); }
    else if (e.key === "Enter" || e.key === "=") { equals(); render(); }
    else if (e.key === "Escape") { clearAll(); render(); }
    else if (e.key === "Backspace") {
      state.current = state.current.length > 1 ? state.current.slice(0, -1) : "0";
      render();
    }
  });

  render();

  // 暴露一些纯函数给测试
  window.__calcCore__ = {
    add: (a, b) => a + b,
    sub: (a, b) => a - b,
    mul: (a, b) => a * b,
    div: (a, b) => (b === 0 ? NaN : a / b),
  };
})();

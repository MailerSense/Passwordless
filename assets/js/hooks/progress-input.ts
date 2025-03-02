import { Hook, makeHook } from "phoenix_typed_hook";

class ProgressInput extends Hook {
  public mounted() {
    this.run("mounted", this.el);
  }

  public updated() {
    this.run("updated", this.el);
  }

  private run(lifecycleMethod: "mounted" | "updated", el: HTMLElement) {
    const p = el as HTMLInputElement;
    p.style.setProperty("--value", p.value);
    p.style.setProperty("--min", p.min == "" ? "0" : p.min);
    p.style.setProperty("--max", p.max == "" ? "100" : p.max);
  }
}

export default makeHook(ProgressInput);

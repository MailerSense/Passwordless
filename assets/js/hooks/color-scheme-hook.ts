import { Hook, makeHook } from "phoenix_typed_hook";

class ColorSchemeHook extends Hook {
  public mounted() {
    this.run("mounted", this.el);
  }

  public updated() {
    this.run("updated", this.el);
  }

  private run(_lifecycleMethod: "mounted" | "updated", el: HTMLElement) {
    (window as any).initScheme();
    el.addEventListener("click", (window as any).toggleScheme);
  }
}

export default makeHook(ColorSchemeHook);

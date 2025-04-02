import { Hook, makeHook } from "./typed-hook";

class ColorSchemeHook extends Hook {
  public mounted() {
    (window as any).initScheme();
    this.el.addEventListener("click", (window as any).toggleScheme);
  }
}

export default makeHook(ColorSchemeHook);

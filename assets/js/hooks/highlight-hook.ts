import hljs from "highlight.js/lib/core";

import { Hook, makeHook } from "./typed-hook";

class HighlightHook extends Hook {
  public mounted() {
    this.run("mounted", this.el);
  }

  public updated() {
    this.run("updated", this.el);
  }

  private run(_lifecycleMethod: "mounted" | "updated", el: HTMLElement) {
    const code = el.querySelector("code");
    if (!code) {
      throw new Error("No code element found");
    }

    hljs.highlightElement(code);
  }
}

export default makeHook(HighlightHook);

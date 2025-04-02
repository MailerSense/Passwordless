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
    hljs.highlightElement(el.querySelector("code")!);
  }
}

export default makeHook(HighlightHook);

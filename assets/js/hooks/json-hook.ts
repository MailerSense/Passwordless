import { create, expand, render } from "../lib/json";
import { Hook, makeHook } from "./typed-hook";

class JSONHook extends Hook {
  public mounted() {
    this.run("mounted", this.el);
  }

  public updated() {
    this.run("updated", this.el);
  }

  private run(_lifecycleMethod: "mounted" | "updated", el: HTMLElement) {
    const json = this.el.dataset.json;

    const shouldExpand = this.el.dataset.expand === "true";

    const tree = create(json);
    render(tree, el);

    if (shouldExpand) {
      expand(tree);
    }
  }
}

export default makeHook(JSONHook);

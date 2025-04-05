import { Hook, makeHook } from "./typed-hook";
import { create, expand, render } from "../lib/json";

class JSONHook extends Hook {
  public mounted() {
    this.run("mounted", this.el);
  }

  public updated() {
    this.run("updated", this.el);
  }

  private run(_lifecycleMethod: "mounted" | "updated", el: HTMLElement) {
    const json = this.el.dataset.json;
    if (!json || json === undefined) {
      throw new Error("No JSON");
    }

    const tree = create(json);
    render(tree, el);
    expand(tree);
  }
}

export default makeHook(JSONHook);

import { Hook, makeHook } from "phoenix_typed_hook";
import { MjmlEditor } from "../lib/mjml/editor";

class EditorHook extends Hook {
  public mounted() {
    this.run("mounted", this.el);
  }

  public updated() {
    this.run("updated", this.el);
  }

  private run(_lifecycleMethod: "mounted" | "updated", el: HTMLElement) {
    const place: HTMLElement | null = el.querySelector(".editor");
    if (place === null) {
      throw new Error("Editor element not found");
    }

    const source: HTMLInputElement | null = el.querySelector(".source");
    if (source === null) {
      throw new Error("Editor element not found");
    }

    new MjmlEditor(place, source);
  }
}

export default makeHook(EditorHook);

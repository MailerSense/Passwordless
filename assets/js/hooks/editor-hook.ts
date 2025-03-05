import Delimiter from "@coolbytes/editorjs-delimiter";
import EditorJS from "@editorjs/editorjs";
import Header from "@editorjs/header";
import Marker from "@editorjs/marker";
import List from "@editorjs/nested-list";
import Quote from "@editorjs/quote";
import Table from "@editorjs/table";
import Warning from "@editorjs/warning";
import { Hook, makeHook } from "phoenix_typed_hook";

class EditorHook extends Hook {
  public mounted() {
    this.run("mounted", this.el);
  }

  public updated() {
    this.run("updated", this.el);
  }

  private run(_lifecycleMethod: "mounted" | "updated", el: HTMLElement) {
    let place: HTMLElement | null = el.querySelector(".editor");
    if (place === null) {
      throw new Error("Editor element not found");
    }

    const editor = new EditorJS({
      holder: place,
      tools: {
        table: Table,
        header: {
          class: Header,
          config: {
            placeholder: "Enter a header",
            levels: [2, 3, 4],
            defaultLevel: 3,
          },
        },
        quote: {
          class: Quote,
          inlineToolbar: true,
        },
        list: {
          class: List,
          inlineToolbar: true,
        },
        marker: Marker,
        delimiter: Delimiter,
        warning: {
          class: Warning,
          inlineToolbar: true,
          config: {
            titlePlaceholder: "Title",
            messagePlaceholder: "Message",
          },
        },
      },
      onChange() {},
    });

    place.addEventListener("focusout", () => {
      editor
        .save()
        .then((outputData) => {})
        .catch((error) => {
          console.warn("Error saving editor content", error);
        });
    });

    place.addEventListener("mouseleave", () => {
      editor.toolbar.close();
    });
  }
}

export default makeHook(EditorHook);

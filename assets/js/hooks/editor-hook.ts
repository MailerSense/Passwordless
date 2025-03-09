import { defaultKeymap } from "@codemirror/commands";
import { html } from "@codemirror/lang-html";
import { EditorState, Prec } from "@codemirror/state";
import { keymap } from "@codemirror/view";
import { tags } from "@lezer/highlight";
import { basicSetup, EditorView } from "codemirror";
import { Hook, makeHook } from "phoenix_typed_hook";

import {
  formatCode,
  indentAndAutocompleteWithTab,
  saveUpdates,
} from "../lib/mjml/helpers";
import { dracula } from "../lib/mjml/theme";

interface FormattedCodeData {
  code: string;
}

class EditorHook extends Hook {
  private view: EditorView | undefined;

  public mounted() {
    this.handleEvent(
      "get_formatted_code",
      (data: Partial<FormattedCodeData>) => {
        if (this.view && data.code) {
          this.view.dispatch({
            changes: {
              from: 0,
              to: this.view.state.doc.length,
              insert: data.code,
            },
          });
        }
      },
    );

    const place: HTMLElement | null = this.el.querySelector(".editor");
    if (place === null) {
      throw new Error("Editor element not found");
    }

    const source: HTMLInputElement | null = this.el.querySelector(".source");
    if (source === null) {
      throw new Error("Editor element not found");
    }

    const formatExt = formatCode((source) => {
      this.pushEvent("format_code", {});
      return true;
    });

    const state = EditorState.create({
      doc: source.value,
      extensions: [
        basicSetup,
        html({ extraTags: tags, selfClosingTags: true }),
        Prec.highest(keymap.of([formatExt])),
        keymap.of([...defaultKeymap, indentAndAutocompleteWithTab]),
        dracula,
        saveUpdates(source),
      ],
    });

    this.view = new EditorView({
      state: state,
      parent: place,
    });
  }

  public updated() {}
}

export default makeHook(EditorHook);

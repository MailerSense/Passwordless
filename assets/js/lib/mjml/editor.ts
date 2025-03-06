import { defaultKeymap } from "@codemirror/commands";
import { html } from "@codemirror/lang-html";
import { EditorState } from "@codemirror/state";
import { EditorView, keymap } from "@codemirror/view";
import { basicSetup } from "codemirror";
import { dracula } from "thememirror";

import { indentAndAutocompleteWithTab, saveUpdates } from "./helpers";
import tags from "./tags";

export class MjmlEditor {
  private place: HTMLElement;
  private source: HTMLInputElement;
  private view: EditorView;

  constructor(place: HTMLElement, source: HTMLInputElement) {
    this.source = source;
    this.place = place;

    let state = EditorState.create({
      doc: source.value,
      extensions: [
        basicSetup,
        html({ extraTags: tags, selfClosingTags: true }),
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
}

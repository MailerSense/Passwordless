import { acceptCompletion, completionStatus } from "@codemirror/autocomplete";
import { indentLess, indentMore } from "@codemirror/commands";
import { EditorView } from "@codemirror/view";

export const indentAndAutocompleteWithTab = {
  key: "Tab",
  preventDefault: true,
  shift: indentLess,
  run: (e: EditorView) => {
    if (!completionStatus(e.state)) return indentMore(e);
    return acceptCompletion(e);
  },
};

export const formatCode = (callback: (e: EditorView) => boolean) => ({
  key: "Mod-s",
  preventDefault: true,
  run: (e: EditorView) => {
    return callback(e);
  },
});

export const saveUpdates = (source: HTMLInputElement) => {
  return EditorView.updateListener.of((e) => {
    if (e.docChanged) {
      source.value = e.state.doc.toString();
      source.dispatchEvent(new Event("input", { bubbles: true }));
    }
  });
};

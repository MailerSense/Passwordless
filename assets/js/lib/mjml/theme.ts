import { tags as t } from "@lezer/highlight";

import {
  HighlightStyle,
  TagStyle,
  syntaxHighlighting,
} from "@codemirror/language";
import { Extension } from "@codemirror/state";
import { EditorView } from "@codemirror/view";

interface Options {
  /**
   * Theme variant. Determines which styles CodeMirror will apply by default.
   */
  variant: Variant;

  /**
   * Settings to customize the look of the editor, like background, gutter, selection and others.
   */
  settings: Settings;

  /**
   * Syntax highlighting styles.
   */
  styles: TagStyle[];
}

type Variant = "light" | "dark";

interface Settings {
  /**
   * Editor background.
   */
  background: string;

  /**
   * Default text color.
   */
  foreground: string;

  /**
   * Caret color.
   */
  caret: string;

  /**
   * Selection background.
   */
  selection: string;

  /**
   * Background of highlighted lines.
   */
  lineHighlight: string;

  /**
   * Gutter background.
   */
  gutterBackground: string;

  /**
   * Text color inside gutter.
   */
  gutterForeground: string;

  /**
   * Font family.
   */
  font: string;
}

const createTheme = ({ variant, settings, styles }: Options): Extension => {
  const theme = EditorView.theme(
    {
      // eslint-disable-next-line @typescript-eslint/naming-convention
      "&": {
        backgroundColor: settings.background,
        color: settings.foreground,
      },
      ".cm-content": {
        caretColor: settings.caret,
      },
      ".cm-scroller": {
        fontFamily: settings.font,
        fontWeight: 500,
        fontSize: "14px",
      },
      ".cm-cursor, .cm-dropCursor": {
        borderLeftColor: settings.caret,
      },
      "&.cm-focused .cm-selectionBackgroundm .cm-selectionBackground, .cm-content ::selection":
        {
          backgroundColor: settings.selection,
        },
      ".cm-activeLine": {
        backgroundColor: settings.lineHighlight,
      },
      ".cm-gutters": {
        backgroundColor: settings.gutterBackground,
        color: settings.gutterForeground,
      },
      ".cm-activeLineGutter": {
        backgroundColor: settings.lineHighlight,
      },
    },
    {
      dark: variant === "dark",
    },
  );

  const highlightStyle = HighlightStyle.define(styles);
  const extension = [theme, syntaxHighlighting(highlightStyle)];

  return extension;
};

export const dracula = createTheme({
  variant: "dark",
  settings: {
    background: "#2d2f3f",
    foreground: "#f8f8f2",
    caret: "#f8f8f0",
    selection: "#44475a",
    gutterBackground: "#282a36",
    gutterForeground: "rgb(144, 145, 148)",
    lineHighlight: "#44475a",
    font: "'JetBrains Mono', monospace",
  },
  styles: [
    {
      tag: t.comment,
      color: "#6272a4",
    },
    {
      tag: [t.string, t.special(t.brace)],
      color: "#f1fa8c",
    },
    {
      tag: [t.number, t.self, t.bool, t.null],
      color: "#bd93f9",
    },
    {
      tag: [t.keyword, t.operator],
      color: "#ff79c6",
    },
    {
      tag: [t.definitionKeyword, t.typeName],
      color: "#8be9fd",
    },
    {
      tag: t.definition(t.typeName),
      color: "#f8f8f2",
    },
    {
      tag: [
        t.className,
        t.definition(t.propertyName),
        t.function(t.variableName),
        t.attributeName,
      ],
      color: "#50fa7b",
    },
  ],
});

export const basic = EditorView.theme(
  {
    "&": {
      color: "#f4f4f5",
      backgroundColor: "#030712",
    },
    ".cm-content": {
      caretColor: "#f9fafb",
    },
    ".cm-scroller": {
      fontFamily: "'JetBrains Mono', monospace",
      fontWeight: 500,
      fontSize: "14px",
    },
    "&.cm-focused .cm-cursor": {
      borderLeftColor: "#f9fafb",
    },
    "&.cm-focused .cm-selectionBackground, ::selection": {
      backgroundColor: "#083344 !important",
    },
    ".cm-selectionBackground, ::selection": {
      backgroundColor: "#083344",
    },
    ".cm-selectionMatch": {
      backgroundColor: "#155e75",
    },
    ".cm-gutters": {
      backgroundColor: "#111827",
      color: "#6b7280",
      border: "none",
    },
    ".ͼe": {
      color: "#93c5fd",
    },
    ".ͼi": {
      color: "#4ade80",
    },
  },
  { dark: true },
);

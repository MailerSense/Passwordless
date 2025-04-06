import BackHook from "./back-hook";
import BadgeSelectHook from "./badge-select-hook";

import ClipboardHook from "./clipboard-hook";
import ColorSchemeHook from "./color-scheme-hook";
import EditorHook from "./editor-hook";
import HighlightHook from "./highlight-hook";
import HTMLPreviewHook from "./html-preview-hook";
import JSONHook from "./json-hook";
import { createLiveToastHook } from "./live-toast";
import ProgressInput from "./progress-input";
import ResetColorSchemeHook from "./reset-color-scheme-hook";
import TippyHook from "./tippy-hook";

export default {
  ClipboardHook,
  ColorSchemeHook,
  ResetColorSchemeHook,
  BadgeSelectHook,
  TippyHook,
  ProgressInput,
  EditorHook,
  HTMLPreviewHook,
  HighlightHook,
  BackHook,
  JSONHook,
  LiveToast: createLiveToastHook(),
};

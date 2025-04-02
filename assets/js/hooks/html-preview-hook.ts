import { Hook, makeHook } from "./typed-hook";

class HTMLPreviewHook extends Hook {
  public mounted() {
    this.run("mounted", this.el);
  }

  public updated() {
    this.run("updated", this.el);
  }

  private run(_lifecycleMethod: "mounted" | "updated", el: HTMLElement) {
    const content = el.innerText;
    if (!content) return;

    const iframeSource = el.dataset.iframe;
    if (!iframeSource || iframeSource === undefined) {
      throw new Error("No iframe source");
    }

    const iframe: HTMLIFrameElement | null = document.getElementById(
      iframeSource,
    ) as HTMLIFrameElement;
    if (!iframe || !iframe.contentWindow) return;

    const scrollX = iframe.contentWindow.scrollX;
    const scrollY = iframe.contentWindow.scrollY;
    const doc = iframe.contentDocument;
    if (!doc) return;
    doc.open();
    doc.write(content);
    doc.close();
    iframe.contentWindow.scrollTo(scrollX, scrollY);
  }
}

export default makeHook(HTMLPreviewHook);

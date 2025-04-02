import { Hook, makeHook } from "./typed-hook";

class BackHook extends Hook {
  public mounted() {
    this.el.addEventListener("click", () => {
      if (
        history.length > 2 &&
        document.referrer.indexOf(window.location.host) !== -1
      ) {
        window.history.back();
      } else {
        const fallback = this.el.dataset.fallback;
        if (!fallback || fallback == null) {
          throw new Error("No fallback");
        }

        (window as any).liveSocket.pushHistoryPatch(fallback, "push", this.el);
      }
    });
  }

  public updated() {}
}

export default makeHook(BackHook);

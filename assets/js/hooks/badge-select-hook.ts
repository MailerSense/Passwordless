import { Hook, makeHook } from "phoenix_typed_hook";

class BadgeSelectHook extends Hook {
  public mounted() {
    this.el.addEventListener("selected-change", (event) => {
      const input = this.el.querySelector(
        'input[type="hidden"]',
      ) as HTMLInputElement;
      if (!input) {
        throw new Error("No hidden input found.");
      }

      input.value = (event as any).detail.value;
      input.dispatchEvent(new Event("input", { bubbles: true }));
    });
  }

  public updated() {
    this.el.dispatchEvent(new CustomEvent("reset"));
  }
}

export default makeHook(BadgeSelectHook);

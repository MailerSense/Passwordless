import { Hook, makeHook } from "./typed-hook";
import OTP from "../lib/otp";

class OTPHook extends Hook {
  public mounted() {
    this.run("mounted", this.el);
  }

  public updated() {
    this.run("updated", this.el);
  }

  private run(lifecycleMethod: "mounted" | "updated", el: HTMLElement) {
    const place: HTMLElement | null = this.el.querySelector(
      ".otp-input-container",
    );
    if (place === null) {
      throw new Error("Editor element not found");
    }

    const source: HTMLInputElement | null =
      this.el.querySelector(".otp-result-input");
    if (source === null) {
      throw new Error("Editor element not found");
    }

    const _initOTPInput = new OTP(place, source);
  }
}

export default makeHook(OTPHook);

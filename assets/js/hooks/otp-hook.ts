import OTP from "../lib/otp";
import { Hook, makeHook } from "./typed-hook";

class OTPHook extends Hook {
  private otp: OTP | null = null;

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

    if (!this.otp) {
      this.otp = new OTP(place, source);
    }
  }
}

export default makeHook(OTPHook);

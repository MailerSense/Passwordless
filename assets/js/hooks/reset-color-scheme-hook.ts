import { Hook, makeHook } from "./typed-hook";

class ResetColorSchemeHook extends Hook {
	public mounted() {
		this.run("mounted", this.el);
	}

	public updated() {
		this.run("updated", this.el);
	}

	private run(_lifecycleMethod: "mounted" | "updated", _el: HTMLElement) {
		(window as any).resetScheme();
	}
}

export default makeHook(ResetColorSchemeHook);

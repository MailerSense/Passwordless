import * as Sentry from "@sentry/browser";

import { Hook, makeHook } from "./typed-hook";

type UserConfig = Sentry.User & {
	org: string;
	app: string;
};

function getDatasetAsPartial<T>(el: HTMLElement): Partial<T> {
	const result: Partial<T> = {};
	for (const key in el.dataset) {
		if (Object.prototype.hasOwnProperty.call(el.dataset, key)) {
			const value = el.dataset[key];
			if (value !== undefined) {
				(result as any)[key] = coerceType(value);
			}
		}
	}
	return result;
}

function coerceType(value: string): string | number | boolean {
	if (value === "true") {
		return true;
	}
	if (value === "false") {
		return false;
	}
	const num = Number(value);
	if (!Number.isNaN(num)) {
		return num;
	}
	return value;
}

class SetSentryUserHook extends Hook {
	public mounted() {
		this.run("mounted", this.el);
	}

	public updated() {
		this.run("updated", this.el);
	}

	private run(_lifecycleMethod: "mounted" | "updated", el: HTMLElement) {
		Sentry.setUser(getDatasetAsPartial<UserConfig>(el));
	}
}

export default makeHook(SetSentryUserHook);

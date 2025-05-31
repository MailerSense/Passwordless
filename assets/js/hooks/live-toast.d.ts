declare module "live_toast" {
	import type { ViewHookInterface } from "phoenix_live_view";

	const createLiveToastHook: () => ViewHookInterface;

	export { createLiveToastHook };
}

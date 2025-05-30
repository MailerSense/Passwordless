// Export components
export { PasswordlessProvider as ConsentManagerProvider } from "./providers/passwordless-provider";

// Export hooks
export { useConsentManager } from "./hooks/use-consent-manager";
export { useTranslations } from "./hooks/use-translations";
export { useColorScheme } from "./hooks/use-color-scheme";
export { useFocusTrap } from "./hooks/use-focus-trap";

// Export client
export {
	configureConsentManager,
	type ConsentManagerInterface,
	// Translation utilities
	prepareTranslationConfig,
	defaultTranslationConfig,
	mergeTranslationConfigs,
	detectBrowserLanguage,
} from "c15t";

// Export types
export type {
	PasswordlessProviderProps as ConsentManagerProviderProps,
	PasswordlessOptions as ConsentManagerOptions,
} from "./types/consent-manager";

import collapse from "@alpinejs/collapse";
import persist from "@alpinejs/persist";
import Alpine from "alpinejs";
import { Socket } from "phoenix";
import "phoenix_html";
import { LiveSocket, SocketOptions } from "phoenix_live_view";
import topbar from "topbar";

import hooks from "./hooks";
import uploaders from "./uploaders";

// Enable dark mode
const applyScheme = (scheme: "light" | "dark") => {
  const css = document.createElement("style");
  css.type = "text/css";
  css.appendChild(
    document.createTextNode(
      `* { 
        -webkit-transition: none !important;
        -moz-transition: none !important;
        -o-transition: none !important;
        -ms-transition: none !important;
        transition: none !important;
      }`,
    ),
  );
  document.head.appendChild(css);

  if (scheme === "light") {
    document.documentElement.classList.remove("dark");
    document
      .querySelectorAll(".color-scheme-dark-icon")
      .forEach((el) => el.classList.remove("hidden"));
    document
      .querySelectorAll(".color-scheme-light-icon")
      .forEach((el) => el.classList.add("hidden"));
    localStorage.scheme = "light";
  } else {
    document.documentElement.classList.add("dark");
    document
      .querySelectorAll(".color-scheme-dark-icon")
      .forEach((el) => el.classList.add("hidden"));
    document
      .querySelectorAll(".color-scheme-light-icon")
      .forEach((el) => el.classList.remove("hidden"));
    localStorage.scheme = "dark";
  }

  window.localStorage.setItem("backpexTheme", scheme);
  document.documentElement.setAttribute("data-theme", scheme);

  const _ = window.getComputedStyle(css).opacity;
  document.head.removeChild(css);
};

const resetScheme = () => {
  const scheme = "light";
  localStorage.scheme = scheme;
  window.localStorage.setItem("backpexTheme", scheme);
  document.documentElement.classList.remove("dark");
  document.documentElement.setAttribute("data-theme", scheme);
};

(window as any).applyScheme = applyScheme;
(window as any).resetScheme = resetScheme;

const toggleScheme = () => {
  if (document.documentElement.classList.contains("dark")) {
    applyScheme("light");
  } else {
    applyScheme("dark");
  }
};

(window as any).toggleScheme = toggleScheme;

const initScheme = () => {
  if (
    localStorage.scheme === "dark" ||
    (!("scheme" in localStorage) &&
      window.matchMedia("(prefers-color-scheme: dark)").matches)
  ) {
    applyScheme("dark");
  } else {
    applyScheme("light");
  }
};

(window as any).initScheme = initScheme;

try {
  initScheme();
} catch (error) {
  console.error(error);
}

function getRandomInt(min: number, max: number): number {
  const minCeiled = Math.ceil(min);
  const maxFloored = Math.floor(max);
  return Math.floor(Math.random() * (maxFloored - minCeiled) + minCeiled);
}

function defaultReconnectAfterMs(tries: number): number {
  const nominalMs =
    [250, 500, 1_000, 2_500, 5_000, 10_000][tries - 1] || 15_000;

  const jitterRatio = getRandomInt(75, 125) / 100;
  return nominalMs * jitterRatio;
}

Alpine.plugin(persist);
Alpine.plugin(collapse);
Alpine.start();

(window as any).Alpine = Alpine;

const csrfToken = document
  .querySelector("meta[name='csrf-token']")!
  .getAttribute("content");

const socketOptions: SocketOptions = {
  hooks,
  uploaders,
  dom: {
    onBeforeElUpdated(from, to) {
      if ((from as any)._x_dataStack) {
        (window as any).Alpine.clone(from, to);
      }

      return true;
    },
    // This allows you to auto focus with <input autofocus />
    onNodeAdded(node: Node) {
      if (node instanceof HTMLElement && node.autofocus) {
        node.focus();
      }

      return node;
    },
  },
  params: { _csrf_token: csrfToken },
};

(socketOptions as any)["reconnectAfterMs"] = defaultReconnectAfterMs;

const liveSocket = new LiveSocket("/live", Socket, socketOptions);

// Show progress bar on live navigation and form submits
topbar.config({
  barColors: { 0: "#1570EF" },
  shadowColor: "#84CAFF",
});
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(500));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
(window as any).liveSocket = liveSocket;

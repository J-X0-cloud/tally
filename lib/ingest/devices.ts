export type ScreenClass = "Mobile" | "Tablet" | "Laptop" | "Desktop";

/** Screen-size class from viewport width; the exact width is never stored. */
export function screenClass(width: number): ScreenClass {
  if (width < 576) return "Mobile";
  if (width < 992) return "Tablet";
  if (width < 1440) return "Laptop";
  return "Desktop";
}

const BROWSERS: Array<[RegExp, string]> = [
  [/SamsungBrowser/, "Samsung Internet"],
  [/Edg\//, "Edge"],
  [/Brave/, "Brave"],
  [/Firefox\//, "Firefox"],
  [/Chrome\/|CriOS\//, "Chrome"],
  [/Safari\//, "Safari"],
];

const SYSTEMS: Array<[RegExp, string]> = [
  [/iPad/, "iPadOS"],
  [/iPhone|iPod/, "iOS"],
  [/Android/, "Android"],
  [/Mac OS X/, "macOS"],
  [/Windows/, "Windows"],
  [/Linux/, "Linux"],
];

export function userAgentInfo(ua: string): { browser: string; os: string } {
  return {
    browser: BROWSERS.find(([re]) => re.test(ua))?.[1] ?? "Other",
    os: SYSTEMS.find(([re]) => re.test(ua))?.[1] ?? "Other",
  };
}

const BOT =
  /bot|crawl|spider|slurp|headless|lighthouse|pingdom|uptime|monitor|preview|python-requests|curl\/|wget/i;

/** Known crawlers, monitors and scripted clients are dropped before counting. */
export const isBot = (ua: string) => !ua || BOT.test(ua);

/** Code shown on the marketing pages, pre-tokenised for highlighting: each line is a list of [text, kind?]. */
export type TokenKind = "comment" | "keyword" | "attr" | "string";
export type CodeSnippet = Array<Array<[string, TokenKind?]>>;

export const SCRIPT_URL = "https://cdn.tallystats.com/t.js";

export const INSTALL_SNIPPET: CodeSnippet = [
  [["<!-- paste before </head> -->", "comment"]],
  [["<script", "keyword"], [" "], ["defer", "attr"]],
  [["  "], ["data-site", "attr"], ["="], ['"harrowfield.co"', "string"]],
  [["  "], ["src", "attr"], ["="], [`"${SCRIPT_URL}"`, "string"], ["></script>", "keyword"]],
  [],
  [["// optional: count a custom event", "comment"]],
  [["tally("], ['"Newsletter signup"', "string"], [", { props: { form: "], ['"footer"', "string"], [" } })"]],
];

export const PURCHASE_SNIPPET: CodeSnippet = [
  [["tally("], ['"Purchase"', "string"], [", {"]],
  [["  revenue: { amount: "], ["64.00", "string"], [", currency: "], ['"USD"', "string"], [" },"]],
  [["  props: { collection: "], ['"fall-glaze"', "string"], [" }"]],
  [["})"]],
];

export const PAYLOAD_SNIPPET: CodeSnippet = [
  [["// the entire request body", "comment"]],
  [["{"]],
  [["  "], ['"n"', "attr"], [": "], ['"pageview"', "string"], [","]],
  [["  "], ['"u"', "attr"], [": "], ['"https://harrowfield.co/shop/mugs"', "string"], [","]],
  [["  "], ['"r"', "attr"], [": "], ['"https://www.google.com/"', "string"], [","]],
  [["  "], ['"w"', "attr"], [": "], ["390", "string"]],
  [["}"]],
];

export const INSTALL_OPTIONS: Array<{
  icon: "code" | "layers" | "shield";
  title: string;
  body: string;
  snippet: CodeSnippet;
}> = [
  {
    icon: "code",
    title: "Plain HTML",
    body: "Paste one tag into the head of every page. Works with any CMS or site builder.",
    snippet: [
      [
        ["<script", "keyword"],
        [" "],
        ["defer", "attr"],
        [" "],
        ["data-site", "attr"],
        ["="],
        ['"you.com"', "string"],
      ],
      [[" "], ["src", "attr"], ["="], [`"${SCRIPT_URL}"`, "string"], ["></script>", "keyword"]],
    ],
  },
  {
    icon: "layers",
    title: "JavaScript package",
    body: "For React, Vue, Svelte and other bundled apps. Route changes are tracked for you.",
    snippet: [
      [
        ["import", "keyword"],
        [" { init } "],
        ["from", "keyword"],
        [" "],
        ['"@tallystats/tracker"', "string"],
      ],
      [["init({ site: "], ['"you.com"', "string"], [" })"]],
    ],
  },
  {
    icon: "shield",
    title: "First-party proxy",
    body: "Serve the script and events from your own domain for the most complete counts.",
    snippet: [
      [["# rewrite on your server or CDN", "comment"]],
      [["/stats/t.js  → cdn.tallystats.com/t.js"]],
      [["/stats/event → api.tallystats.com/event"]],
    ],
  },
];

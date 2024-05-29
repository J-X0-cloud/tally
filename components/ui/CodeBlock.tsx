import { Fragment } from "react";
import type { CSSProperties, ReactNode } from "react";

import type { CodeSnippet } from "@/lib/data/snippets";

const CLASS = { comment: "c", keyword: "k", attr: "a", string: "s" } as const;

interface CodeBlockProps {
  snippet: CodeSnippet;
  /** File name or request line shown in the bar above the code. */
  title?: string;
  /** Right-aligned note in the bar (size, status). */
  badge?: ReactNode;
  style?: CSSProperties;
}

export function CodeBlock({ snippet, title, badge, style }: CodeBlockProps) {
  return (
    <div className="code" style={style}>
      {title ? (
        <div className="bar">
          {title}
          {badge ? <b>{badge}</b> : null}
        </div>
      ) : null}
      <pre>
        {snippet.map((line, i) => (
          <Fragment key={i}>
            {i > 0 ? "\n" : null}
            {line.map(([text, kind], j) =>
              kind ? (
                <span key={j} className={CLASS[kind]}>
                  {text}
                </span>
              ) : (
                <Fragment key={j}>{text}</Fragment>
              ),
            )}
          </Fragment>
        ))}
      </pre>
    </div>
  );
}

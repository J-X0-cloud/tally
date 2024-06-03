import clsx from "clsx";
import type { CSSProperties } from "react";

interface SectionHeadProps {
  eyebrow?: string;
  title: string;
  lede?: string;
  centered?: boolean;
  titleStyle?: CSSProperties;
}

export function SectionHead({ eyebrow, title, lede, centered = false, titleStyle }: SectionHeadProps) {
  return (
    <div className={clsx("sec-h", centered && "center")}>
      {eyebrow ? <span className="eyebrow">{eyebrow}</span> : null}
      <h2 style={titleStyle}>{title}</h2>
      {lede ? <p className="lede">{lede}</p> : null}
    </div>
  );
}

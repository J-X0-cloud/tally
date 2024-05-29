import clsx from "clsx";
import Link from "next/link";
import type { CSSProperties, ReactNode } from "react";

/** p = persimmon primary, g = ghost, d = dark, w = white, o = outline on dark. */
export type ButtonVariant = "p" | "g" | "d" | "w" | "o";

interface ButtonLinkProps {
  href: string;
  variant: ButtonVariant;
  small?: boolean;
  className?: string;
  style?: CSSProperties;
  children: ReactNode;
}

export function ButtonLink({ href, variant, small = false, className, style, children }: ButtonLinkProps) {
  const cls = clsx("btn", `btn-${variant}`, small && "btn-sm", className);
  return href.startsWith("/") ? (
    <Link className={cls} href={href} style={style}>
      {children}
    </Link>
  ) : (
    <a className={cls} href={href} style={style}>
      {children}
    </a>
  );
}

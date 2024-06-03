import Link from "next/link";

/** Tally mark: four strokes crossed by a fifth. */
export function Mark({ size = 28 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" aria-hidden="true">
      <rect width="32" height="32" rx="9" fill="#E4572E" />
      <g stroke="#fff" strokeWidth={2.6} strokeLinecap="round">
        <path d="M9 9v14M13.5 9v14M18 9v14M22.5 9v14" />
        <path d="M6.5 20.5 25.5 11" stroke="#FFD7B8" />
      </g>
    </svg>
  );
}

export function Logo({ className = "logo", size }: { className?: string; size?: number }) {
  return (
    <Link className={className} href="/" aria-label="Tally home">
      <Mark size={size} />
      <span>tally</span>
    </Link>
  );
}

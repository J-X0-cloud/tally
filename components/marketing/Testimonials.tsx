import { TESTIMONIALS } from "@/lib/data/home";

export function Testimonials() {
  return (
    <div className="quotes">
      {TESTIMONIALS.map((t) => (
        <figure key={t.name} className="q">
          <p>“{t.quote}”</p>
          <figcaption className="who">
            <span className="av" style={{ background: t.color }}>
              {t.name[0]}
            </span>
            <span>
              <b>{t.name}</b>
              <small>{t.role}</small>
            </span>
          </figcaption>
        </figure>
      ))}
    </div>
  );
}

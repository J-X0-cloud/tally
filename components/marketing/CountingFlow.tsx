import { COUNTING_STEPS } from "@/lib/data/privacy";

export function CountingFlow() {
  return (
    <div className="flow">
      {COUNTING_STEPS.map((s) => (
        <div key={s.title} className="fs">
          <h3>{s.title}</h3>
          <p>{s.body}</p>
          <code>{s.code}</code>
        </div>
      ))}
    </div>
  );
}

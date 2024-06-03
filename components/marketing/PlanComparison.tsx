import { Icon } from "@/components/ui/Icon";
import { COMPARISON, PLANS } from "@/lib/data/pricing";

function Cell({ value }: { value: string | boolean }) {
  if (value === true) return <Icon name="check" size={18} strokeWidth={2.4} />;
  if (value === false) return <span className="muted">–</span>;
  return <>{value}</>;
}

export function PlanComparison() {
  return (
    <div className="tbox">
      <table className="tbl">
        <thead>
          <tr>
            <th>Feature</th>
            {PLANS.map((p) => (
              <th key={p.name}>{p.name}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {COMPARISON.map(([feature, ...cells]) => (
            <tr key={feature}>
              <td>{feature}</td>
              {cells.map((c, i) => (
                <td key={i}>
                  <Cell value={c} />
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

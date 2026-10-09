import { Icon } from "@/components/ui/Icon";
import type { PricingCatalog } from "@/types/pricing";

function Cell({ value }: { value: string | boolean }) {
  if (value === true) return <Icon name="check" size={18} strokeWidth={2.4} />;
  if (value === false) return <span className="muted">–</span>;
  return <>{value}</>;
}

export function PlanComparison({ catalog }: { catalog: PricingCatalog }) {
  return (
    <div className="tbox">
      <table className="tbl">
        <thead>
          <tr>
            <th>Feature</th>
            {catalog.plans.map((p) => (
              <th key={p.name}>{p.name}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {catalog.comparison.map(({ feature, values }) => (
            <tr key={feature}>
              <td>{feature}</td>
              {values.map((c, i) => (
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

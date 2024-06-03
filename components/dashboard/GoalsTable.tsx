import { compact, usd } from "@/lib/format";
import { goalRows } from "@/lib/metrics";
import type { RangeKey } from "@/types/analytics";

export function GoalsTable({ range }: { range: RangeKey }) {
  return (
    <table className="gt">
      <thead>
        <tr>
          <th>Goal</th>
          <th className="num">Uniques</th>
          <th className="num">Total</th>
          <th className="num">CR</th>
        </tr>
      </thead>
      <tbody>
        {goalRows(range).map((g) => (
          <tr key={g.name}>
            <td>
              <span className="gn">{g.name}</span>
              {g.revenue !== null ? <small className="grev">{usd(g.revenue)} revenue</small> : null}
            </td>
            <td className="num">{compact(g.uniques)}</td>
            <td className="num">{compact(g.total)}</td>
            <td className="num">
              <b>{g.conversionRate.toFixed(1)}%</b>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

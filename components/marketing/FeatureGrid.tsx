import { Icon } from "@/components/ui/Icon";
import { FEATURES } from "@/lib/data/home";

export function FeatureGrid() {
  return (
    <div className="fgrid">
      {FEATURES.map((f) => (
        <div key={f.title} className="fcell">
          <div className="ic">
            <Icon name={f.icon} size={20} />
          </div>
          <h3>{f.title}</h3>
          <p>{f.body}</p>
        </div>
      ))}
    </div>
  );
}

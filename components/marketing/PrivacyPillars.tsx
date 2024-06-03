import { Icon } from "@/components/ui/Icon";
import { PRIVACY_PILLARS } from "@/lib/data/home";

export function PrivacyPillars() {
  return (
    <div className="pcols">
      {PRIVACY_PILLARS.map((p) => (
        <div key={p.title} className="pc">
          <div className="ic">
            <Icon name={p.icon} size={20} />
          </div>
          <h3>{p.title}</h3>
          <p>{p.body}</p>
        </div>
      ))}
    </div>
  );
}

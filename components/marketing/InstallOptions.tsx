import { CodeBlock } from "@/components/ui/CodeBlock";
import { Icon } from "@/components/ui/Icon";
import { INSTALL_OPTIONS } from "@/lib/data/snippets";

export function InstallOptions() {
  return (
    <div className="inst">
      {INSTALL_OPTIONS.map((o) => (
        <div key={o.title} className="card">
          <div className="fcell" style={{ padding: 0, border: 0 }}>
            <div className="ic">
              <Icon name={o.icon} size={20} />
            </div>
          </div>
          <h3>{o.title}</h3>
          <p>{o.body}</p>
          <CodeBlock snippet={o.snippet} />
        </div>
      ))}
    </div>
  );
}

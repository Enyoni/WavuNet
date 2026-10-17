sv import from ..services.rulesService { listDetectionRules, createDetectionRule }
import from "@jac/runtime" { Link }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.button { Button }
import from .ui.badge { Badge }
import from .ui.input { Input }

async def _load_rules() -> list[dict] {
    return await listDetectionRules();
}

def:pub FraudRules() -> JsxElement {
    has rules: list[dict] = [];
    has rule_name: str = "";
    has typology: str = "Mule network";
    has description: str = "";
    has threshold: str = "75";
    has loading: bool = True;
    has saving: bool = False;
    has error_message: str = "";
    has notice: str = "";

    async can with entry {
        try { rules = await _load_rules(); error_message = ""; }
        except Exception { error_message = "Unable to load detection rules."; }
        loading = False;
    }

    async def save_rule() {
        if len(rule_name.strip()) < 3 { error_message = "Enter a rule name with at least 3 characters."; return; }
        if len(description.strip()) < 10 { error_message = "Add a description with at least 10 characters."; return; }
        if not threshold.isdigit() { error_message = "Risk threshold must be a whole number from 1 to 100."; return; }
        numeric_threshold = int(threshold);
        if numeric_threshold < 1 or numeric_threshold > 100 { error_message = "Risk threshold must be between 1 and 100."; return; }
        saving = True;
        error_message = "";
        notice = "";
        try {
            result = await createDetectionRule(rule_name, typology, description, numeric_threshold);
            if result["ok"] as bool {
                rules = await _load_rules();
                rule_name = "";
                description = "";
                threshold = "75";
                notice = "Detection rule saved to the graph.";
            } else {
                error_message = result["error"] as str;
            }
        } except Exception {
            error_message = "Unable to save the rule. Please try again.";
        }
        saving = False;
    }

    return <main className="min-h-screen bg-muted/40 text-foreground">
        <div className="mx-auto flex w-full max-w-6xl flex-col gap-6 p-4 sm:p-6 lg:p-8 animate-in fade-in slide-in-from-bottom-2 duration-500">
            <header className="flex flex-wrap items-center justify-between gap-4 rounded-xl border bg-card p-4 shadow-sm">
                <div className="flex items-center gap-3"><div className="flex size-10 items-center justify-center rounded-xl bg-primary text-primary-foreground text-lg font-bold">W</div><div><div className="text-lg font-semibold tracking-tight">WavuNet</div><div className="text-xs text-muted-foreground">Detection policy workspace</div></div></div>
                <nav className="flex items-center gap-1 rounded-lg border bg-muted/40 p-1" aria-label="Primary navigation"><Link to="/" className="rounded-md px-3 py-2 text-sm text-muted-foreground hover:bg-background hover:text-foreground">Dashboard</Link><Link to="/rules" className="rounded-md bg-background px-3 py-2 text-sm font-medium shadow-sm">Rules</Link><Link to="/transactions" className="rounded-md px-3 py-2 text-sm text-muted-foreground hover:bg-background hover:text-foreground">Transactions</Link></nav>
            </header>
            <section><p className="text-xs font-medium uppercase tracking-[0.16em] text-primary">Threat operations / configuration</p><h1 className="mt-1 text-2xl font-semibold tracking-tight sm:text-3xl">Detection rules</h1><p className="mt-1 text-sm text-muted-foreground">Create and manage explainable rules that guide fraud investigations.</p></section>
            {notice and <div className="rounded-lg border border-emerald-600/20 bg-emerald-600/5 px-4 py-3 text-sm text-emerald-700">{notice}</div>}
            {error_message != "" and <div className="rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3 text-sm text-destructive">{error_message}</div>}
            <div className="grid items-start gap-6 lg:grid-cols-5">
                <Card className="shadow-sm lg:col-span-2"><CardHeader><CardTitle>Create a detection rule</CardTitle><CardDescription>Rules are stored in the Jac graph and available after reload.</CardDescription></CardHeader><CardContent className="flex flex-col gap-4">
                    <label className="flex flex-col gap-2 text-sm font-medium">Rule name<Input value={rule_name} onChange={lambda (e: ChangeEvent) { rule_name = e.target.value; }} placeholder="Rapid mule pass-through" maxLength={80} /></label>
                    <label className="flex flex-col gap-2 text-sm font-medium">Typology<select value={typology} onChange={lambda (e: ChangeEvent) { typology = e.target.value; }} className="h-9 rounded-md border bg-background px-3 text-sm"><option>Mule network</option><option>Layering</option><option>Shared device</option><option>Account takeover</option><option>Agent abuse</option><option>Reversal fraud</option></select></label>
                    <label className="flex flex-col gap-2 text-sm font-medium">Rule description<textarea value={description} onChange={lambda (e: ChangeEvent) { description = e.target.value; }} placeholder="Describe the suspicious behavior and evidence this rule should detect." maxLength={500} rows={4} className="resize-y rounded-md border bg-background px-3 py-2 text-sm font-normal outline-none focus:ring-2 focus:ring-ring" /></label>
                    <label className="flex flex-col gap-2 text-sm font-medium">Minimum risk threshold <span className="text-xs font-normal text-muted-foreground">Integer from 1 to 100</span><Input type="number" min="1" max="100" value={threshold} onChange={lambda (e: ChangeEvent) { threshold = e.target.value; }} /></label>
                    <Button onClick={save_rule} disabled={saving}>{"Save detection rule" if not saving else "Saving rule…"}</Button>
                </CardContent></Card>
                <Card className="shadow-sm lg:col-span-3"><CardHeader className="flex flex-row items-start justify-between gap-4"><div><CardTitle>Saved rules</CardTitle><CardDescription>Configured graph-backed detection policies</CardDescription></div><Badge variant="outline">{str(len(rules))} rules</Badge></CardHeader><CardContent className="flex flex-col gap-3">
                    {loading and <div className="rounded-lg border bg-muted/30 p-6 text-sm text-muted-foreground">Loading saved rules…</div>}
                    {not loading and len(rules) == 0 and <div className="rounded-lg border border-dashed p-10 text-center"><div className="font-medium">No custom rules yet</div><p className="mt-1 text-sm text-muted-foreground">Create a rule to add an explainable detection policy to this workspace.</p></div>}
                    {not loading and <div className="flex flex-col gap-3">{for rule in rules {
                        <article key={rule["rule_name"]} className="rounded-lg border bg-background p-4"><div className="flex flex-wrap items-start justify-between gap-3"><div><h2 className="font-semibold">{rule["rule_name"]}</h2><p className="mt-1 text-sm text-muted-foreground">{rule["description"]}</p></div><Badge variant="secondary">{rule["typology"]}</Badge></div><div className="mt-4 flex items-center justify-between border-t pt-3 text-xs text-muted-foreground"><span>Minimum risk threshold: <strong className="text-foreground">{str(rule["threshold"] as int)}</strong></span><span className="text-emerald-700">Enabled</span></div></article>
                    }}</div>}
                </CardContent></Card>
            </div>
            <footer className="border-t pt-4 text-xs text-muted-foreground">Rule changes are persisted to the Jac graph. Human review remains required for enforcement actions.</footer>
        </div>
    </main>;
}

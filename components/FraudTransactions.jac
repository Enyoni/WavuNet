sv import from ..services.fraudService { getFraudMonitor, getTransactions }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.badge { Badge }
import from "@jac/runtime" { Link, useLocation }

async def _load_detail_data() -> dict {
    monitor = await getFraudMonitor();
    transactions = await getTransactions();
    return {"alerts": monitor["alerts"], "transactions": transactions};
}

def:pub FraudTransactions() -> JsxElement {
    location = useLocation();
    query = location.search;
    view = "alerts";
    if query.find("view=exposure") >= 0 { view = "exposure"; }
    elif query.find("view=rings") >= 0 { view = "rings"; }
    elif query.find("view=transactions") >= 0 { view = "transactions"; }

    has alerts: list[dict] = [];
    has transactions: list[dict] = [];
    has search_text: str = "";
    has loading: bool = True;
    has error_message: str = "";

    async can with entry {
        try {
            data = await _load_detail_data();
            alerts = data["alerts"] as list[dict];
            transactions = data["transactions"] as list[dict];
        } except Exception {
            error_message = "Unable to load fraud records.";
        }
        loading = False;
    }

    def change_search(e: ChangeEvent) { search_text = e.target.value; }

    heading = "Active alert records" if view == "alerts" else "Exposure records" if view == "exposure" else "Fraud ring records" if view == "rings" else "Ingested transactions";
    filtered_alerts = [a for a in alerts if (view != "rings" or a["pattern"] == "Mule network" or a["pattern"] == "Layering" or a["pattern"] == "Shared device") and (search_text.strip() == "" or search_text.lower() in (a["alert_id"] as str).lower() or search_text.lower() in (a["title"] as str).lower() or search_text.lower() in (a["pattern"] as str).lower())];
    filtered_transactions = [t for t in transactions if search_text.strip() == "" or search_text.lower() in (t["transaction_id"] as str).lower() or search_text.lower() in (t["sender_account"] as str).lower() or search_text.lower() in (t["receiver_account"] as str).lower()];

    return <main className="min-h-screen bg-muted/40 text-foreground"><div className="mx-auto flex w-full max-w-6xl flex-col gap-6 p-4 sm:p-6 lg:p-8 animate-in fade-in slide-in-from-bottom-2 duration-500">
        <header className="flex flex-wrap items-center justify-between gap-4 rounded-xl border bg-card p-4 shadow-sm"><div className="flex items-center gap-3"><div className="flex size-10 items-center justify-center rounded-xl bg-primary text-primary-foreground text-lg font-bold">W</div><div><div className="text-lg font-semibold tracking-tight">WavuNet</div><div className="text-xs text-muted-foreground">Fraud intelligence workspace</div></div></div><nav className="flex items-center gap-1 rounded-lg border bg-muted/40 p-1" aria-label="Primary navigation"><Link to="/" className="rounded-md px-3 py-2 text-sm text-muted-foreground hover:bg-background hover:text-foreground">Dashboard</Link><Link to="/rules" className="rounded-md px-3 py-2 text-sm text-muted-foreground hover:bg-background hover:text-foreground">Rules</Link><Link to="/transactions" className="rounded-md bg-background px-3 py-2 text-sm font-medium shadow-sm">Transactions</Link></nav></header>
        <section><p className="text-xs font-medium uppercase tracking-[0.16em] text-primary">Threat operations / records</p><h1 className="mt-1 text-2xl font-semibold tracking-tight sm:text-3xl">{heading}</h1><p className="mt-1 text-sm text-muted-foreground">Open a record to compare its exposure, source, risk signal, and investigation status.</p></section>
        <div className="flex flex-wrap gap-2"><Link to="/transactions?view=alerts" className="rounded-full border px-3 py-1.5 text-sm bg-card hover:bg-muted">Alerts</Link><Link to="/transactions?view=exposure" className="rounded-full border px-3 py-1.5 text-sm bg-card hover:bg-muted">Exposure</Link><Link to="/transactions?view=rings" className="rounded-full border px-3 py-1.5 text-sm bg-card hover:bg-muted">Fraud rings</Link><Link to="/transactions?view=transactions" className="rounded-full border px-3 py-1.5 text-sm bg-card hover:bg-muted">Transactions</Link></div>
        {error_message != "" and <div className="rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3 text-sm text-destructive">{error_message}</div>}
        {loading and <Card><CardContent className="p-8 text-sm text-muted-foreground">Loading records…</CardContent></Card>}
        {not loading and <Card className="shadow-sm"><CardHeader><CardTitle>{heading}</CardTitle><CardDescription>Search by record ID, account, alert title, or typology.</CardDescription></CardHeader><CardContent className="flex flex-col gap-4"><input value={search_text} onChange={change_search} placeholder="Search records" className="h-10 w-full rounded-md border bg-background px-3 text-sm sm:max-w-sm" />
            {view == "transactions" and <div className="text-sm text-muted-foreground">{str(len(filtered_transactions))} transactions</div>}
            {view != "transactions" and <div className="text-sm text-muted-foreground">{str(len(filtered_alerts))} alert records</div>}
            {view == "transactions" and len(filtered_transactions) == 0 and <div className="rounded-lg border border-dashed p-10 text-center"><div className="font-medium">No transactions match</div><p className="mt-1 text-sm text-muted-foreground">Ingest an event from the dashboard or adjust your search.</p></div>}
            {view == "transactions" and <div className="flex flex-col divide-y rounded-lg border">{for tx in filtered_transactions {<article key={tx["transaction_id"]} className="flex flex-wrap items-center justify-between gap-3 p-4"><div><h2 className="font-medium">{tx["transaction_id"]}</h2><p className="mt-1 text-xs text-muted-foreground">{tx["sender_account"]} → {tx["receiver_account"]} · {tx["institution"]}</p></div><div className="flex items-center gap-3"><Badge variant="secondary">{tx["source"]}</Badge><div className="text-right"><div className="font-semibold tabular-nums">{tx["currency"]} {str(tx["amount"] as float)}</div><div className="text-xs text-muted-foreground">Risk {str(tx["risk_score"] as int)}</div></div></div></article>}}</div>}
            {view != "transactions" and len(filtered_alerts) == 0 and <div className="rounded-lg border border-dashed p-10 text-center"><div className="font-medium">No matching records</div><p className="mt-1 text-sm text-muted-foreground">Try another category or search term.</p></div>}
            {view != "transactions" and <div className="flex flex-col divide-y rounded-lg border">{for alert in filtered_alerts {<article key={alert["alert_id"]} className="flex flex-wrap items-start justify-between gap-4 p-4"><div className="min-w-0"><div className="flex flex-wrap items-center gap-2"><h2 className="font-medium">{alert["title"]}</h2><Badge variant="secondary">{alert["pattern"]}</Badge></div><p className="mt-1 text-xs text-muted-foreground">{alert["alert_id"]} · {alert["location"]} · {alert["time_label"]}</p><p className="mt-3 max-w-3xl text-sm leading-relaxed">{alert["evidence"]}</p><p className="mt-2 text-xs text-muted-foreground">Status: {alert["status"]}</p></div><div className="text-right"><div className="font-semibold tabular-nums">KES {str(alert["amount"] as float)}</div><div className="mt-1 text-xs text-muted-foreground">Risk score {str(alert["score"] as int)}</div></div></article>}}</div>}
        </CardContent></Card>}
        <footer className="border-t pt-4 text-xs text-muted-foreground">WavuNet Fraud Intelligence · Synthetic demonstration environment</footer>
    </div></main>;
}

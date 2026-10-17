sv import from ..services.fraudService { getFraudMonitor, getTransactions, ingestTransaction, triageAlert, resetFraudDemo }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.button { Button }
import from .ui.badge { Badge }
import from "@jac/runtime" { Link }
import from "@jac/runtime" { useNavigate }

async def _load_alerts() -> list[dict] {
    data = await getFraudMonitor();
    return data["alerts"] as list[dict];
}

def:pub FraudMonitor() -> JsxElement {
    nav = useNavigate();
    has alerts: list[dict] = [];
    has loading: bool = True;
    has error_message: str = "";
    has selected_id: str = "AL-2048";
    has notice: str = "";
    has transaction_id: str = "";
    has transaction_amount: str = "";
    has sender_account: str = "";
    has receiver_account: str = "";
    has transactions: list[dict] = [];
    has feed_state: str = "idle";

    async can with entry {
        try { alerts = await _load_alerts(); error_message = ""; }
        except Exception { error_message = "Unable to load the fraud monitor."; }
        try { transactions = await getTransactions(); feed_state = "idle"; } except Exception { feed_state = "error"; }
        loading = False;
    }

    async def refresh_alerts() {
        loading = True;
        try { alerts = await _load_alerts(); error_message = ""; }
        except Exception { error_message = "Unable to load the fraud monitor."; }
        try { transactions = await getTransactions(); } except Exception { feed_state = "error"; }
        loading = False;
    }

    async def ingest_event() {
        if len(transaction_id.strip()) < 3 { notice = "Transaction ID must contain at least 3 characters."; return; }
        if not transaction_amount.isdigit() { notice = "Enter a valid whole-number transaction amount."; return; }
        if len(sender_account.strip()) < 2 or len(receiver_account.strip()) < 2 { notice = "Enter both sender and receiver accounts."; return; }
        feed_state = "sending";
        result = await ingestTransaction(transaction_id, "2026-10-16T18:00:00Z", float(transaction_amount), "KES", sender_account, receiver_account, "Mobile money", "Demo institution", "Nairobi, KE", "Interbank transfer", 92, "WavuNet stream", 82);
        if result["ok"] as bool {
            transactions = await getTransactions();
            alerts = await _load_alerts();
            notice = "Transaction event accepted and saved to the graph.";
            transaction_id = "";
            transaction_amount = "";
            sender_account = "";
            receiver_account = "";
            feed_state = "idle";
        } else {
            notice = result["error"] as str;
            feed_state = "error";
        }
    }

    async def set_status(alert_id: str, status: str) {
        _ = await triageAlert(alert_id, status);
        alerts = await _load_alerts();
        selected_id = alert_id;
        notice = f"{alert_id} marked {status.lower()}.";
    }

    async def reset_demo() {
        _ = await resetFraudDemo();
        alerts = await _load_alerts();
        selected_id = "AL-2048";
        notice = "Synthetic demo data restored.";
    }

    return <main className="min-h-screen bg-muted/40 text-foreground">
        <div className="mx-auto flex w-full max-w-[1600px] flex-col gap-6 p-4 sm:p-6 lg:p-8 animate-in fade-in slide-in-from-bottom-2 duration-500">
            <header className="flex flex-wrap items-center justify-between gap-4 rounded-xl border bg-card p-4 shadow-sm">
                <div className="flex items-center gap-3">
                    <div className="flex size-10 items-center justify-center rounded-xl bg-primary text-primary-foreground text-lg font-bold">W</div>
                    <div><div className="text-lg font-semibold tracking-tight">WavuNet</div><div className="text-xs text-muted-foreground">Fraud intelligence workspace</div></div>
                </div>
                <div className="flex flex-wrap items-center gap-2">
                    <span className="mr-2 flex items-center gap-2 text-xs text-muted-foreground"><span className="size-2 rounded-full bg-emerald-500"/>All systems operational</span>
                    <nav className="flex items-center gap-1 rounded-lg border bg-muted/40 p-1" aria-label="Primary navigation"><Link to="/" className="rounded-md bg-background px-3 py-2 text-sm font-medium shadow-sm">Dashboard</Link><Link to="/rules" className="rounded-md px-3 py-2 text-sm text-muted-foreground hover:bg-background hover:text-foreground">Rules</Link><Link to="/transactions" className="rounded-md px-3 py-2 text-sm text-muted-foreground hover:bg-background hover:text-foreground">Transactions</Link></nav>
                    <Button variant="outline" size="sm" onClick={reset_demo}>Reset demo</Button>
                    <Button size="sm" onClick={refresh_alerts}>Refresh intelligence</Button>
                </div>
            </header>

            <section className="flex flex-wrap items-end justify-between gap-3">
                <div><p className="text-xs font-medium uppercase tracking-[0.16em] text-primary">Threat operations / live monitor</p><h1 className="mt-1 text-2xl font-semibold tracking-tight sm:text-3xl">Fraud intelligence</h1><p className="mt-1 text-sm text-muted-foreground">Investigate suspicious activity across connected financial networks.</p></div>
                <div className="flex items-center gap-2 rounded-lg border bg-card px-3 py-2 text-xs text-muted-foreground"><span className="size-2 rounded-full bg-emerald-500"/>Synthetic data environment <span className="border-l pl-2">Updated just now</span></div>
            </section>

            <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
                <button onClick={lambda { nav("/transactions?view=alerts"); }} className="text-left"><Card className="shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-md"><CardContent className="p-5"><div className="flex items-center justify-between text-sm text-muted-foreground">Active alerts<span aria-hidden="true">↗</span></div><div className="mt-2 text-3xl font-semibold tabular-nums">{str(len(alerts))}</div><div className="mt-2 text-xs text-rose-600">Open alert records</div></CardContent></Card></button>
                <button onClick={lambda { nav("/transactions?view=exposure"); }} className="text-left"><Card className="shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-md"><CardContent className="p-5"><div className="flex items-center justify-between text-sm text-muted-foreground">Amount at risk<span aria-hidden="true">↗</span></div><div className="mt-2 text-3xl font-semibold tabular-nums">KES 617K</div><div className="mt-2 text-xs text-muted-foreground">Open alert exposure details</div></CardContent></Card></button>
                <button onClick={lambda { nav("/transactions?view=rings"); }} className="text-left"><Card className="shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-md"><CardContent className="p-5"><div className="flex items-center justify-between text-sm text-muted-foreground">Fraud rings detected<span aria-hidden="true">↗</span></div><div className="mt-2 text-3xl font-semibold tabular-nums">12</div><div className="mt-2 text-xs text-muted-foreground">Open linked ring alerts</div></CardContent></Card></button>
                <button onClick={lambda { nav("/transactions?view=transactions"); }} className="text-left"><Card className="shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-md"><CardContent className="p-5"><div className="flex items-center justify-between text-sm text-muted-foreground">Detection rate<span aria-hidden="true">↗</span></div><div className="mt-2 text-3xl font-semibold tabular-nums">94.2%</div><div className="mt-2 text-xs text-emerald-600">Review detected transaction records</div></CardContent></Card></button>
            </section>

            {notice and <div className="rounded-lg border border-primary/20 bg-primary/5 px-4 py-3 text-sm">{notice}</div>}
            {error_message != "" and <div className="rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3 text-sm text-destructive">{error_message} <button className="ml-2 underline" onClick={refresh_alerts}>Retry</button></div>}
            {loading and <div className="rounded-xl border bg-card p-8 text-sm text-muted-foreground">Loading fraud intelligence…</div>}

            {not loading and <section className="grid gap-4 xl:grid-cols-12">
                <Card className="shadow-sm xl:col-span-7">
                    <CardHeader className="flex flex-row items-start justify-between gap-4"><div><CardTitle>Priority alerts</CardTitle><CardDescription>Ranked by risk score and amount exposed</CardDescription></div><Badge variant="outline">{str(len(alerts))} open</Badge></CardHeader>
                    <CardContent className="flex flex-col gap-3">
                        {for alert in alerts {
                            <button key={alert["alert_id"]} onClick={lambda { selected_id = alert["alert_id"] as str; }} className={"w-full rounded-lg border p-4 text-left transition-colors " + ("border-primary/40 bg-primary/5" if selected_id == alert["alert_id"] else "bg-background hover:bg-muted/40")}>
                                <div className="flex flex-wrap items-start justify-between gap-3"><div className="flex min-w-0 items-start gap-3"><div className={"mt-1 size-2.5 shrink-0 rounded-full " + ("bg-rose-500" if (alert["score"] as int) >= 90 else "bg-amber-500")}/><div><div className="font-medium">{alert["title"]}</div><div className="mt-1 text-xs text-muted-foreground">{alert["alert_id"]} · {alert["pattern"]} · {alert["time_label"]}</div></div></div><div className="text-right"><div className="font-semibold tabular-nums">KES {str(alert["amount"] as float)}</div><div className="mt-1 text-xs text-muted-foreground">Risk score <span className="font-semibold text-foreground">{str(alert["score"] as int)}</span></div></div></div>
                                <div className="mt-3 flex flex-wrap items-center justify-between gap-2"><div className="text-xs text-muted-foreground">{alert["location"]}</div><Badge variant="secondary">{alert["status"]}</Badge></div>
                            </button>
                        }}
                        {len(alerts) == 0 and <div className="rounded-lg border border-dashed p-10 text-center"><div className="font-medium">No active alerts</div><p className="mt-1 text-sm text-muted-foreground">Reset the demo to restore synthetic investigation data.</p></div>}
                    </CardContent>
                </Card>

                <div className="flex flex-col gap-4 xl:col-span-5">
                    <Card className="shadow-sm"><CardHeader><CardTitle>Investigation brief</CardTitle><CardDescription>Evidence-led case context for analyst review</CardDescription></CardHeader><CardContent>
                        {for alert in alerts {
                            if selected_id == alert["alert_id"] {
                                <div key={alert["alert_id"]} className="flex flex-col gap-4">
                                    <div className="flex items-start justify-between gap-3"><div><div className="text-lg font-semibold">{alert["title"]}</div><div className="mt-1 text-xs text-muted-foreground">{alert["alert_id"]} · {alert["time_label"]}</div></div><Badge variant="outline">Score {str(alert["score"] as int)}</Badge></div>
                                    <div className="rounded-lg bg-muted/50 p-4"><div className="mb-1 text-xs font-semibold uppercase tracking-wide text-muted-foreground">Observed evidence</div><p className="text-sm leading-relaxed">{alert["evidence"]}</p></div>
                                    <div className="grid grid-cols-2 gap-3"><div className="rounded-lg border p-3"><div className="text-xs text-muted-foreground">Pattern</div><div className="mt-1 text-sm font-medium">{alert["pattern"]}</div></div><div className="rounded-lg border p-3"><div className="text-xs text-muted-foreground">Exposure</div><div className="mt-1 text-sm font-medium tabular-nums">KES {str(alert["amount"] as float)}</div></div></div>
                                    <div className="flex flex-wrap gap-2"><Button size="sm" onClick={lambda { set_status(alert["alert_id"] as str, "Investigating"); }}>Mark investigating</Button><Button size="sm" variant="outline" onClick={lambda { set_status(alert["alert_id"] as str, "Resolved"); }}>Resolve</Button><Button size="sm" variant="outline" onClick={lambda { set_status(alert["alert_id"] as str, "False positive"); }}>False positive</Button></div>
                                </div>
                            }
                        }}
                        {len(alerts) == 0 and <p className="text-sm text-muted-foreground">Select an alert to review its evidence and take action.</p>}
                    </CardContent></Card>
                    <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-1 2xl:grid-cols-2">
                        <Card className="shadow-sm"><CardHeader className="pb-3"><CardTitle className="text-base">Network signal</CardTitle><CardDescription>Linked movement · 3 accounts</CardDescription></CardHeader><CardContent><div className="relative flex min-h-28 items-center justify-between gap-1 overflow-hidden rounded-lg bg-muted/30 px-3"><div className="absolute left-[20%] right-[20%] top-1/2 border-t border-dashed border-primary/40"/><div className="z-10 flex flex-col items-center gap-1"><div className="flex size-11 items-center justify-center rounded-full border-2 border-rose-400 bg-card text-xs font-semibold">4821</div><span className="text-[10px] text-muted-foreground">Kisiwa</span></div><div className="z-10 flex flex-col items-center gap-1"><div className="flex size-11 items-center justify-center rounded-full border-2 border-rose-400 bg-card text-xs font-semibold">1190</div><span className="text-[10px] text-muted-foreground">Pamoja</span></div><div className="z-10 flex flex-col items-center gap-1"><div className="flex size-11 items-center justify-center rounded-full border-2 border-amber-400 bg-card text-xs font-semibold">7604</div><span className="text-[10px] text-muted-foreground">Kisiwa</span></div></div><div className="mt-3 flex items-center justify-between text-xs text-muted-foreground"><span>Shared device cluster</span><span className="font-medium text-rose-600">High confidence</span></div></CardContent></Card>
                        <Card className="shadow-sm"><CardHeader className="pb-3"><CardTitle className="text-base">Hotspot overview</CardTitle><CardDescription>Flagged activity by region</CardDescription></CardHeader><CardContent><div className="relative flex h-28 items-center justify-center overflow-hidden rounded-lg bg-muted/30"><div className="absolute size-20 rounded-full bg-rose-500/10 blur-md"/><div className="absolute left-[22%] top-[23%] size-3 rounded-full bg-rose-500 shadow-[0_0_0_8px_rgba(244,63,94,0.14)]"/><div className="absolute left-[53%] top-[52%] size-2 rounded-full bg-amber-500 shadow-[0_0_0_7px_rgba(245,158,11,0.16)]"/><div className="absolute right-[20%] bottom-[20%] size-2 rounded-full bg-rose-400 shadow-[0_0_0_6px_rgba(244,63,94,0.12)]"/><span className="relative text-xs font-medium text-muted-foreground">KENYA · 4 flagged regions</span></div><div className="mt-3 flex justify-between text-xs"><span>Nairobi <span className="text-muted-foreground">12 alerts</span></span><span>Mombasa <span className="text-muted-foreground">8 alerts</span></span></div></CardContent></Card>
                    </div>
                    <Card className="shadow-sm"><CardHeader className="pb-3"><CardTitle>Transaction stream</CardTitle><CardDescription>Send normalized transaction events into the graph-backed intelligence pipeline.</CardDescription></CardHeader><CardContent className="flex flex-col gap-4">
                        <div className="grid gap-3 sm:grid-cols-2">
                            <label className="flex flex-col gap-1.5 text-xs font-medium">Transaction ID<input value={transaction_id} onChange={lambda (e: ChangeEvent) { transaction_id = e.target.value; }} placeholder="TX-KE-10527" className="h-9 rounded-md border bg-background px-3 text-sm font-normal" /></label>
                            <label className="flex flex-col gap-1.5 text-xs font-medium">Amount (KES)<input type="number" min="1" value={transaction_amount} onChange={lambda (e: ChangeEvent) { transaction_amount = e.target.value; }} placeholder="12500" className="h-9 rounded-md border bg-background px-3 text-sm font-normal" /></label>
                            <label className="flex flex-col gap-1.5 text-xs font-medium">Sender account<input value={sender_account} onChange={lambda (e: ChangeEvent) { sender_account = e.target.value; }} placeholder="•• 4821" className="h-9 rounded-md border bg-background px-3 text-sm font-normal" /></label>
                            <label className="flex flex-col gap-1.5 text-xs font-medium">Receiver account<input value={receiver_account} onChange={lambda (e: ChangeEvent) { receiver_account = e.target.value; }} placeholder="•• 1190" className="h-9 rounded-md border bg-background px-3 text-sm font-normal" /></label>
                        </div>
                        <div className="flex flex-wrap items-center justify-between gap-3"><p className="text-xs text-muted-foreground">Source: WavuNet stream · risk scored at ingestion</p><Button size="sm" onClick={ingest_event} disabled={feed_state == "sending"}>{"Sending event…" if feed_state == "sending" else "Send transaction event"}</Button></div>
                        {notice != "" and <p className="rounded-md bg-muted/50 px-3 py-2 text-sm">{notice}</p>}
                        <div className="border-t pt-3"><div className="mb-2 flex items-center justify-between"><h3 className="text-sm font-medium">Recent ingested transactions</h3><Badge variant="outline">{str(len(transactions))} records</Badge></div>
                            {feed_state == "error" and <p className="mb-2 text-sm text-destructive">Unable to load the transaction feed. Try sending again.</p>}
                            {len(transactions) == 0 and <p className="rounded-lg border border-dashed p-4 text-center text-xs text-muted-foreground">No events ingested yet. Send a transaction above to begin.</p>}
                            {for tx in transactions[:5] {<div key={tx["transaction_id"]} className="flex flex-wrap items-center justify-between gap-2 border-b py-2 text-xs"><span className="font-medium">{tx["transaction_id"]}</span><span className="text-muted-foreground">{tx["sender_account"]} → {tx["receiver_account"]}</span><span className="font-medium">{tx["currency"]} {str(tx["amount"] as float)}</span><Badge variant="secondary">{tx["source"]}</Badge></div>}}
                        </div>
                    </CardContent></Card>
                </div>
            </section>}
            <footer className="flex flex-wrap justify-between gap-2 border-t pt-4 text-xs text-muted-foreground"><span>WavuNet Fraud Intelligence · Synthetic demonstration environment</span><span>Human review required for every final action</span></footer>
        </div>
    </main>;
}

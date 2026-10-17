node Account {
    has account_id: str;
    has institution: str;
    has risk: int = 0;
}

node FraudAlert {
    has alert_id: str;
    has title: str;
    has pattern: str;
    has amount: float;
    has score: int;
    has location: str;
    has time_label: str;
    has evidence: str;
    has status: str = "New";
}

node Transaction {
    has transaction_id: str;
    has timestamp: str;
    has amount: float;
    has currency: str;
    has sender_account: str;
    has receiver_account: str;
    has channel: str;
    has institution: str;
    has location: str;
    has transfer_type: str;
    has confidence_score: int;
    has source: str;
    has risk_score: int = 0;
}

edge Transferred: Account --> Account {
    has amount: float = 0.0;
}

def _seed_alerts() -> list[dict] {
    return [
        {"alert_id": "AL-2048", "title": "Rapid pass-through activity", "pattern": "Mule network", "amount": 284000.0, "score": 96, "location": "Nairobi, KE", "time_label": "2 min ago", "evidence": "4 accounts shared one device; 91% of incoming funds moved onward within 11 minutes."},
        {"alert_id": "AL-2047", "title": "Circular fund movement", "pattern": "Layering", "amount": 176500.0, "score": 89, "location": "Mombasa, KE", "time_label": "18 min ago", "evidence": "A 6-account cycle returned funds to the origin through 3 institutions."},
        {"alert_id": "AL-2046", "title": "Shared device cluster", "pattern": "Shared device", "amount": 92300.0, "score": 78, "location": "Kisumu, KE", "time_label": "42 min ago", "evidence": "7 wallets accessed from the same device identifier in a 24-hour window."},
        {"alert_id": "AL-2045", "title": "High-velocity cash out", "pattern": "Agent abuse", "amount": 64100.0, "score": 72, "location": "Nakuru, KE", "time_label": "1 hr ago", "evidence": "Agent cash-out volume is 4.2× its 30-day baseline; 12 linked accounts."}
    ];
}

def:pub getFraudMonitor() -> dict {
    alerts = [a for a in [root -->][?:FraudAlert]];
    if len(alerts) == 0 {
        for item in _seed_alerts() {
            _ = root ++> FraudAlert(alert_id=item["alert_id"] as str, title=item["title"] as str, pattern=item["pattern"] as str, amount=item["amount"] as float, score=item["score"] as int, location=item["location"] as str, time_label=item["time_label"] as str, evidence=item["evidence"] as str);
        }
        alerts = [a for a in [root -->][?:FraudAlert]];
        account_a = (root ++> Account(account_id="•• 4821", institution="Kisiwa Bank", risk=92)) as Account;
        account_b = (root ++> Account(account_id="•• 1190", institution="Pamoja Mobile", risk=87)) as Account;
        account_c = (root ++> Account(account_id="•• 7604", institution="Kisiwa Bank", risk=73)) as Account;
        account_a +>:Transferred(amount=142000.0):+> account_b;
        account_b +>:Transferred(amount=118000.0):+> account_c;
        account_c +>:Transferred(amount=24000.0):+> account_a;
    }
    return {"alerts": [{"alert_id": a.alert_id, "title": a.title, "pattern": a.pattern, "amount": a.amount, "score": a.score, "status": a.status, "location": a.location, "time_label": a.time_label, "evidence": a.evidence} for a in alerts]};
}

import from typing { Generator }

def:pub streamTransaction(transaction_id: str, sender_account: str, receiver_account: str, amount: float, source: str) -> Generator {
    def stream -> Generator[str, None, None] {
        yield "accepted";
        yield f"processing:{transaction_id}:{sender_account}:{receiver_account}:{amount}:{source}";
        yield "complete";
    }
    report stream();
}

def:pub getTransactions() -> list[dict] {
    return [{"transaction_id": item.transaction_id, "timestamp": item.timestamp, "amount": item.amount, "currency": item.currency, "sender_account": item.sender_account, "receiver_account": item.receiver_account, "channel": item.channel, "institution": item.institution, "location": item.location, "transfer_type": item.transfer_type, "confidence_score": item.confidence_score, "source": item.source, "risk_score": item.risk_score} for item in [root -->][?:Transaction]];
}

def:pub ingestTransaction(transaction_id: str, timestamp: str, amount: float, currency: str, sender_account: str, receiver_account: str, channel: str, institution: str, location: str, transfer_type: str, confidence_score: int, source: str, risk_score: int) -> dict {
    clean_id = transaction_id.strip();
    if len(clean_id) < 3 or len(clean_id) > 100 { return {"ok": False, "error": "Transaction ID must be 3 to 100 characters."}; }
    if amount <= 0.0 { return {"ok": False, "error": "Amount must be greater than zero."}; }
    if len(currency.strip()) != 3 { return {"ok": False, "error": "Currency must be a three-letter code."}; }
    if len(sender_account.strip()) < 2 or len(receiver_account.strip()) < 2 { return {"ok": False, "error": "Sender and receiver accounts are required."}; }
    if len(source.strip()) == 0 or len(institution.strip()) == 0 or len(timestamp.strip()) == 0 { return {"ok": False, "error": "Timestamp, source, and institution are required."}; }
    if confidence_score < 0 or confidence_score > 100 or risk_score < 0 or risk_score > 100 { return {"ok": False, "error": "Confidence and risk scores must be between 0 and 100."}; }
    for existing in [root -->][?:Transaction] {
        if existing.transaction_id == clean_id { return {"ok": False, "duplicate": True, "error": "Transaction ID already ingested."}; }
    }
    _ = root ++> Transaction(transaction_id=clean_id, timestamp=timestamp.strip(), amount=amount, currency=currency.strip().upper(), sender_account=sender_account.strip(), receiver_account=receiver_account.strip(), channel=channel.strip(), institution=institution.strip(), location=location.strip(), transfer_type=transfer_type.strip(), confidence_score=confidence_score, source=source.strip(), risk_score=risk_score);
    if risk_score >= 75 {
        alert_id = "TX-" + clean_id;
        _ = root ++> FraudAlert(alert_id=alert_id, title="High-risk ingested transaction", pattern="Transaction risk threshold", amount=amount, score=risk_score, location=location.strip(), time_label="Just ingested", evidence=f"Source {source.strip()} · {institution.strip()} · {transfer_type.strip()} · confidence {confidence_score}%.");
    }
    return {"ok": True, "transaction_id": clean_id, "alert_created": risk_score >= 75};
}

def:pub triageAlert(alert_id: str, status: str) -> dict {
    if status != "Investigating" and status != "Resolved" and status != "False positive" { return {"ok": False}; }
    for alert in [root -->][?:FraudAlert] {
        if alert.alert_id == alert_id { alert.status = status; return {"ok": True, "alert_id": alert_id, "status": status}; }
    }
    return {"ok": False};
}

def:pub resetFraudDemo() -> dict {
    for alert in [root -->][?:FraudAlert] { del alert; }
    for account in [root -->][?:Account] { del account; }
    for transaction in [root -->][?:Transaction] { del transaction; }
    return {"ok": True};
}

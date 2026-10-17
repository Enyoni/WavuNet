import from services.fraudService { getFraudMonitor, getTransactions, ingestTransaction, streamTransaction, triageAlert, resetFraudDemo }
import from services.rulesService { listDetectionRules, createDetectionRule }
import from components.FraudMonitor { FraudMonitor }
import from components.FraudRules { FraudRules }
import from components.FraudTransactions { FraudTransactions }
import ".styles.global.css";
import from "@jac/runtime" { Router, Routes, Route }

def:pub app() -> JsxElement {
    return <Router><Routes><Route path="/" element={<FraudMonitor />} /><Route path="/rules" element={<FraudRules />} /><Route path="/transactions" element={<FraudTransactions />} /></Routes></Router>;
}

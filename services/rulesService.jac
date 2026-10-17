node DetectionRule {
    has rule_name: str;
    has typology: str;
    has description: str;
    has threshold: int;
    has enabled: bool = True;
}

def:pub listDetectionRules() -> list[dict] {
    return [{"rule_name": item.rule_name, "typology": item.typology, "description": item.description, "threshold": item.threshold, "enabled": item.enabled} for item in [root -->][?:DetectionRule]];
}

def:pub createDetectionRule(rule_name: str, typology: str, description: str, threshold: int) -> dict {
    clean_name = rule_name.strip();
    clean_typology = typology.strip();
    clean_description = description.strip();
    if len(clean_name) < 3 or len(clean_name) > 80 { return {"ok": False, "error": "Rule name must be 3 to 80 characters."}; }
    if clean_typology not in ["Mule network", "Layering", "Shared device", "Account takeover", "Agent abuse", "Reversal fraud"] { return {"ok": False, "error": "Choose a supported typology."}; }
    if len(clean_description) < 10 or len(clean_description) > 500 { return {"ok": False, "error": "Description must be 10 to 500 characters."}; }
    if threshold < 1 or threshold > 100 { return {"ok": False, "error": "Risk threshold must be between 1 and 100."}; }
    rule = root ++> DetectionRule(rule_name=clean_name, typology=clean_typology, description=clean_description, threshold=threshold);
    return {"ok": True, "rule_name": rule.rule_name, "typology": rule.typology, "description": rule.description, "threshold": rule.threshold, "enabled": rule.enabled};
}

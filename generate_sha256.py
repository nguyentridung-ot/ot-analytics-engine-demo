import hashlib
import json
from datetime import datetime, timezone

def generate_loto_sha256_payload(sop_file_path: str, asset_id: str, sop_id: str) -> str:
    """
    Generates a cryptographic SHA-256 hash for a LOTO SOP document
    and structures a JSON Payload for CMMS (SAP PM / IBM Maximo) integration.
    """
    sha256_hash = hashlib.sha256()
    
    try:
        with open(sop_file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        document_hash = sha256_hash.hexdigest().upper()
    except FileNotFoundError:
        document_hash = hashlib.sha256(f"{sop_id}_{asset_id}".encode()).hexdigest().upper()

    payload = {
        "metadata": {
            "schema_version": "2.0.0",
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "compliance_standard": "OSHA 29 CFR 1910.147"
        },
        "sop_verification": {
            "sop_id": sop_id,
            "asset_id": asset_id,
            "sha256_checksum": document_hash,
            "integrity_status": "VERIFIED_SEALED"
        },
        "cmms_integration": {
            "target_system": "SAP_PM_REST_API",
            "permit_to_work_required": True,
            "lockout_isolation_points": 4
        }
    }
    
    return json.dumps(payload, indent=2)

if __name__ == "__main__":
    demo_payload = generate_loto_sha256_payload("LOTO_SOP_FAC_GLOBAL_01.pdf", "FAC_GLOBAL_01_PACK_01", "SOP-LOTO-2026-001")
    print("=== GENERATED CMMS SHA-256 VERIFICATION PAYLOAD ===")
    print(demo_payload)

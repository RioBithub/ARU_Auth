#!/usr/bin/env python3
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROFILE_PATH = ROOT / "config" / "user-profile.json"
OUTPUT_PATH = ROOT / "config" / "aru-realm.json"

APPS = [
    ("siap-aru", "https://siap.aruraharja.co.id"),
    ("aru-ticketing", "https://i-ticketing.aruraharja.co.id"),
    ("aru-meet", "https://meet.aruraharja.co.id"),
    ("aru-qrsign", "https://qrsign.aruraharja.co.id"),
    ("aru-link", "https://link.aruraharja.co.id"),
    ("aru-vhc", "https://vhc.aruraharja.co.id"),
]

CLAIMS = [
    "employee_id",
    "unit",
    "position",
    "employment_status",
    "work_location",
    "work_location_other",
    "phone_number",
]


def mapper(attribute: str) -> dict:
    return {
        "name": f"aru-{attribute}",
        "protocol": "openid-connect",
        "protocolMapper": "oidc-usermodel-attribute-mapper",
        "consentRequired": False,
        "config": {
            "user.attribute": attribute,
            "claim.name": attribute,
            "jsonType.label": "String",
            "id.token.claim": "true",
            "access.token.claim": "true",
            "userinfo.token.claim": "true",
        },
    }


def client(client_id: str, origin: str) -> dict:
    return {
        "clientId": client_id,
        "name": client_id,
        "enabled": True,
        "publicClient": True,
        "protocol": "openid-connect",
        "standardFlowEnabled": True,
        "directAccessGrantsEnabled": False,
        "implicitFlowEnabled": False,
        "serviceAccountsEnabled": False,
        "redirectUris": [f"{origin}/auth/aru/callback"],
        "webOrigins": [origin],
        "attributes": {
            "pkce.code.challenge.method": "S256",
            "post.logout.redirect.uris": f"{origin}/*",
        },
        "protocolMappers": [mapper(attribute) for attribute in CLAIMS],
    }


def main() -> None:
    profile = json.loads(PROFILE_PATH.read_text(encoding="utf-8"))
    profile_json = json.dumps(profile, ensure_ascii=False, separators=(",", ":"))

    realm = {
        "realm": "aru",
        "displayName": "ARU Account",
        "displayNameHtml": "<strong>ARU Account</strong>",
        "enabled": True,
        "sslRequired": "external",
        "registrationAllowed": True,
        "registrationEmailAsUsername": True,
        "rememberMe": True,
        "verifyEmail": False,
        "loginWithEmailAllowed": True,
        "duplicateEmailsAllowed": False,
        "resetPasswordAllowed": True,
        "editUsernameAllowed": False,
        "bruteForceProtected": True,
        "permanentLockout": False,
        "failureFactor": 5,
        "waitIncrementSeconds": 60,
        "quickLoginCheckMilliSeconds": 1000,
        "minimumQuickLoginWaitSeconds": 60,
        "maxFailureWaitSeconds": 900,
        "maxDeltaTimeSeconds": 43200,
        "internationalizationEnabled": True,
        "supportedLocales": ["id", "en"],
        "defaultLocale": "id",
        "loginTheme": "aru",
        "roles": {
            "realm": [
                {"name": "aru-pending", "description": "Akun baru menunggu verifikasi administrator"},
                {"name": "aru-user", "description": "Pegawai ARU terverifikasi"},
                {"name": "aru-admin", "description": "Administrator ARU Account"},
            ]
        },
        "groups": [
            {"name": "pending-users", "realmRoles": ["aru-pending"]},
            {"name": "employees", "realmRoles": ["aru-user"]},
            {"name": "auth-admins", "realmRoles": ["aru-admin", "aru-user"]},
        ],
        "defaultGroups": ["/pending-users"],
        "clients": [client(client_id, origin) for client_id, origin in APPS],
        "components": {
            "org.keycloak.userprofile.UserProfileProvider": [
                {
                    "id": "5d11e727-cad8-4e24-9a8b-7ce9c30d5187",
                    "providerId": "declarative-user-profile",
                    "subComponents": {},
                    "config": {"kc.user.profile.config": [profile_json]},
                }
            ]
        },
    }

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    if OUTPUT_PATH.is_dir():
        shutil.rmtree(OUTPUT_PATH)

    OUTPUT_PATH.write_text(
        json.dumps(realm, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Generated {OUTPUT_PATH}")


if __name__ == "__main__":
    main()

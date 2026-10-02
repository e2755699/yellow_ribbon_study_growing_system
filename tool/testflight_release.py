"""Use the existing Codemagic Apple integration; never export its credentials.

Inspect by default. --distribute is an explicit release action after backend
readiness. It only adds this pubspec build to the existing internal group and
does not submit to public App Store review or create testers.
"""
import json
import os
from pathlib import Path
import re
import sys
import time
from urllib.parse import urlencode
from urllib.request import Request, urlopen
import jwt

APP = "6746115397"
GROUP = "43256c93-cc4f-4453-839f-1eadf6205b97"
ORIGIN = "https://api.appstoreconnect.apple.com"


def api(path, method="GET", data=None):
    now = int(time.time())
    token = jwt.encode(
        {"iss": os.environ["APP_STORE_CONNECT_ISSUER_ID"], "iat": now,
         "exp": now + 300, "aud": "appstoreconnect-v1"},
        os.environ["APP_STORE_CONNECT_PRIVATE_KEY"], algorithm="ES256",
        headers={"kid": os.environ["APP_STORE_CONNECT_KEY_IDENTIFIER"], "typ": "JWT"})
    request = Request(ORIGIN + path, method=method,
                      data=None if data is None else json.dumps(data).encode(),
                      headers={"Authorization": "Bearer " + token, "Content-Type": "application/json"})
    with urlopen(request, timeout=45) as response:
        payload = response.read()
        return json.loads(payload) if payload else {}


def builds(number, version):
    return api("/v1/builds?" + urlencode({"filter[app]": APP,
        "filter[version]": number, "filter[preReleaseVersion.version]": version}))['data']


def main():
    match = re.search(r"^version:\s*([\d.]+)\+(\d+)\s*$", Path("pubspec.yaml").read_text(), re.M)
    if not match:
        raise RuntimeError("Cannot determine release version")
    version, number = match.groups()
    found = builds(number, version)
    if len(found) != 1:
        raise RuntimeError("Expected exactly one uploaded build")
    build = found[0]
    group = api("/v1/betaGroups/" + GROUP)['data']
    if group['attributes']['name'] != 'yellowribbon' or not group['attributes']['isInternalGroup']:
        raise RuntimeError("Existing internal group does not match")
    if '--distribute' in sys.argv:
        if build['attributes']['processingState'] != 'VALID' or build['attributes']['expired']:
            raise RuntimeError("Build has not completed Apple processing")
        if build['attributes'].get('usesNonExemptEncryption') is None:
            previous = builds(str(int(number) - 1), version)
            if len(previous) != 1 or previous[0]['attributes'].get('usesNonExemptEncryption') is not False:
                raise RuntimeError("Prior encryption declaration requires review; no answer was guessed")
            # This release adds OS Keychain storage; network encryption remains
            # the same Firebase/TLS stack as the prior approved release.
            api('/v1/builds/' + build['id'], 'PATCH', {'data': {
                'type': 'builds', 'id': build['id'],
                'attributes': {'usesNonExemptEncryption': False}}})
        api('/v1/betaGroups/' + GROUP + '/relationships/builds', 'POST',
            {'data': [{'type': 'builds', 'id': build['id']}]})
    members = api('/v1/betaGroups/' + GROUP + '/builds?limit=200')['data']
    detail = api('/v1/builds/' + build['id'] + '/buildBetaDetail')['data']['attributes']
    result = {'appId': APP, 'version': version, 'buildNumber': number,
              'buildId': build['id'], 'processingState': build['attributes']['processingState'],
              'usesNonExemptEncryption': api('/v1/builds/' + build['id'])['data']['attributes'].get('usesNonExemptEncryption'),
              'group': 'yellowribbon', 'inGroup': any(b['id'] == build['id'] for b in members),
              'betaDetail': detail}
    Path('testflight-status.json').write_text(json.dumps(result, indent=2))
    print(json.dumps(result))
    if '--distribute' in sys.argv and (not result['inGroup'] or detail.get('internalBuildState') != 'IN_BETA_TESTING'):
        raise RuntimeError("Apple has not confirmed internal testing availability")


if __name__ == '__main__':
    main()

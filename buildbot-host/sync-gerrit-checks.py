#!/usr/bin/env python3

import argparse
import json
import os
import re
import sys

import requests


def get_checks(args, auth):
    r = requests.get(f"{args.gerrit}/a/plugins/checks/checkers/", auth=auth)
    print(r.url)
    json_txt = r.text.removeprefix(")]}'\n")
    json_data = json.loads(json_txt)
    checks = set()
    for check in json_data:
        if check["status"] != "ENABLED":
            continue
        checks.add(check["uuid"].removeprefix("buildbot:"))
    return checks


def relevant_builder(name):
    if re.search(r"openvpn3", name):
        return False
    if re.search(r"ovpn-dco", name):
        return False
    if re.search(r"^__", name):
        return False
    return True


def get_builders(args):
    rm = requests.get(f"{args.buildbot}/api/v2/masters")
    print(rm.url)
    masters = [m for m in rm.json()["masters"] if m["active"]]
    assert len(masters) == 1
    master_id = masters[0]["masterid"]
    rb = requests.get(f"{args.buildbot}/api/v2/masters/{master_id}/builders")
    print(rb.url)
    builders = set()
    for builder in rb.json()["builders"]:
        if relevant_builder(builder["name"]):
            check_name = builder["name"].replace("=", "")
            builders.add(check_name)
    return builders


def sync_checks(checks, builders, args, auth):
    missing_checks = builders - checks
    print("missing_checks:\n" + "\n".join(sorted(missing_checks)))
    obsolete_checks = checks - builders
    print("obsolete_checks:\n" + "\n".join(sorted(obsolete_checks)))

    for check in missing_checks:
        print(f"create {check}")
        check_data = {
            "uuid": f"buildbot:{check}",
            "name": check,
            "repository": "openvpn",
            "blocking": ["STATE_NOT_PASSING"],
        }
        rc = requests.post(
            f"{args.gerrit}/a/plugins/checks/checkers/", json=check_data, auth=auth
        )
        rc.raise_for_status()

    for check in obsolete_checks:
        print(f"disable {check}")
        check_data = {
            "status": "DISABLED",
            "blocking": [],
        }
        rc = requests.post(
            f"{args.gerrit}/a/plugins/checks/checkers/buildbot:{check}",
            json=check_data,
            auth=auth,
        )
        rc.raise_for_status()


def main():
    parser = argparse.ArgumentParser(
        prog="sync-gerrit-checks",
        description="Sync Buildbot builders and Gerrit checks",
    )
    parser.add_argument("-g", "--gerrit", default="https://gerrit.openvpn.net")
    parser.add_argument(
        "-b", "--buildbot", default="http://buildbot-host.openvpn.in:8010"
    )
    args = parser.parse_args()

    gerrit_user = os.environ["GERRIT_USER"]
    gerrit_pass = os.environ["GERRIT_PASS"]
    auth = requests.auth.HTTPBasicAuth(gerrit_user, gerrit_pass)

    checks = get_checks(args, auth)
    builders = get_builders(args)
    sync_checks(checks, builders, args, auth)


if __name__ == "__main__":
    sys.exit(main())

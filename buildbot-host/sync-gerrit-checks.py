#!/usr/bin/env python3

import argparse
import json
import os
import re
import sys

import requests

# Buildmaster responses are pathologically slow when gzipped
BUILDBOT_HEADERS = {"Accept-Encoding": "identity"}

# Force schedulers for the OpenVPN 2 branches. A builder that is not attached
# to all of them is branch-specific and must not be a required check.
OPENVPN_BRANCH_FORCE_SCHEDULERS = [
    "openvpn-force-main",
    "openvpn-force-release26",
    "openvpn-force-release27",
]
REQUIRED_BLOCKING = ["STATE_NOT_PASSING"]


def checker_scheme(repository):
    """Checker UUID scheme for a Gerrit repository.

    Must match gerrit_checker_scheme() in buildmaster/master.cfg.
    """
    if repository == "openvpn":
        return "buildbot"
    return f"buildbot-{repository}"


def get_checks(args, auth, repository):
    r = requests.get(f"{args.gerrit}/a/plugins/checks/checkers/", auth=auth)
    print(r.url)
    json_txt = r.text.removeprefix(")]}'\n")
    json_data = json.loads(json_txt)
    prefix = f"{checker_scheme(repository)}:"
    checks = {}
    for check in json_data:
        if check["status"] != "ENABLED":
            continue
        if check.get("repository") != repository:
            continue
        if not check["uuid"].startswith(prefix):
            continue
        checks[check["uuid"].removeprefix(prefix)] = check
    return checks


def relevant_builder(name, repository):
    if re.search(r"^__", name):
        return False
    # openvpn-rfc builders only report on the openvpn-rfc repository
    is_rfc_builder = re.search(r"-openvpn-rfc$", name) is not None
    if repository == "openvpn-rfc":
        return is_rfc_builder
    if is_rfc_builder:
        return False
    if re.search(r"openvpn3", name):
        return False
    if re.search(r"ovpn-dco", name):
        return False
    return True


def get_builders(args, repository):
    rm = requests.get(f"{args.buildbot}/api/v2/masters", headers=BUILDBOT_HEADERS)
    print(rm.url)
    masters = [m for m in rm.json()["masters"] if m["active"]]
    # assert len(masters) == 1
    masters = sorted(masters, key=lambda master: master["last_active"], reverse=True)
    master_id = masters[0]["masterid"]
    rb = requests.get(
        f"{args.buildbot}/api/v2/masters/{master_id}/builders",
        headers=BUILDBOT_HEADERS,
    )
    print(rb.url)
    builders = set()
    for builder in rb.json()["builders"]:
        if relevant_builder(builder["name"], repository):
            check_name = builder["name"].replace("=", "")
            builders.add(check_name)
    return builders


def get_branch_specific_builders(args):
    """Check names of builders that only run for some OpenVPN 2 branches.

    Builders not attached to any of the branch force schedulers (e.g.
    smoketest builders) are run for all branches and are not included.
    """
    rf = requests.get(
        f"{args.buildbot}/api/v2/forceschedulers", headers=BUILDBOT_HEADERS
    )
    print(rf.url)
    rf.raise_for_status()
    counts = {}
    found = set()
    for scheduler in rf.json()["forceschedulers"]:
        if scheduler["name"] not in OPENVPN_BRANCH_FORCE_SCHEDULERS:
            continue
        found.add(scheduler["name"])
        for name in scheduler["builder_names"]:
            check_name = name.replace("=", "")
            counts[check_name] = counts.get(check_name, 0) + 1
    missing = set(OPENVPN_BRANCH_FORCE_SCHEDULERS) - found
    if missing:
        raise RuntimeError(f"force schedulers not found: {sorted(missing)}")
    return {
        name
        for name, count in counts.items()
        if count < len(OPENVPN_BRANCH_FORCE_SCHEDULERS)
    }


def wanted_blocking(check, branch_specific):
    if check in branch_specific:
        return []
    return REQUIRED_BLOCKING


def sync_checks(checks, builders, branch_specific, args, auth, repository):
    scheme = checker_scheme(repository)
    print(f"repository {repository} (scheme {scheme}):")
    missing_checks = builders - checks.keys()
    print("missing_checks:\n" + "\n".join(sorted(missing_checks)))
    obsolete_checks = checks.keys() - builders
    print("obsolete_checks:\n" + "\n".join(sorted(obsolete_checks)))

    for check in missing_checks:
        print(f"create {check}")
        check_data = {
            "uuid": f"{scheme}:{check}",
            "name": check,
            "repository": repository,
            "blocking": wanted_blocking(check, branch_specific),
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
            f"{args.gerrit}/a/plugins/checks/checkers/{scheme}:{check}",
            json=check_data,
            auth=auth,
        )
        rc.raise_for_status()

    for check in sorted(checks.keys() & builders):
        blocking = wanted_blocking(check, branch_specific)
        if sorted(checks[check].get("blocking", [])) == sorted(blocking):
            continue
        print(f"set {check} {'required' if blocking else 'not required'}")
        rc = requests.post(
            f"{args.gerrit}/a/plugins/checks/checkers/{scheme}:{check}",
            json={"blocking": blocking},
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
        "-b", "--buildbot", default="http://buildbot.community.aws.openvpn.in:8010"
    )
    parser.add_argument(
        "-r",
        "--repository",
        action="append",
        help="Gerrit repository to sync checkers for (can be repeated, "
        "default: openvpn, openvpn-private and openvpn-rfc)",
    )
    args = parser.parse_args()
    repositories = args.repository or ["openvpn", "openvpn-private", "openvpn-rfc"]

    gerrit_user = os.environ["GERRIT_USER"]
    gerrit_pass = os.environ["GERRIT_PASS"]
    auth = requests.auth.HTTPBasicAuth(gerrit_user, gerrit_pass)

    branch_specific = get_branch_specific_builders(args)
    for repository in repositories:
        builders = get_builders(args, repository)
        checks = get_checks(args, auth, repository)
        sync_checks(checks, builders, branch_specific, args, auth, repository)


if __name__ == "__main__":
    sys.exit(main())

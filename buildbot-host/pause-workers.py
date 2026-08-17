#!/usr/bin/env python3

import argparse
import os
import re
import sys

import requests

# Only the fields we actually look at, which keeps the response small.
FIELDS = ["workerid", "name", "paused", "pause_reason", "graceful", "connected_to"]

RETRIES = 3
TIMEOUT = 5

# Accept-Encoding: identity, because requests would ask for gzip and compressed
# responses can take 20+ seconds. Buildbot writes the response one
# json.iterencode() piece at a time (~23k pieces here) from a worker thread, and
# every piece releases and reacquires the GIL inside the compressor; when the
# master is busy each of those costs a GIL switch interval.
#
# Accept: application/json, because it makes buildbot emit compact rather than
# indent=2 JSON -- 2.4x fewer bytes.
#
# The uncompressed path has its own flaw: buildbot computes Content-Length in a
# separate serialization pass, and on a live master the worker data changes
# between the two passes, so ~7% of responses are a few bytes shorter than
# promised and the client raises IncompleteRead. Hence get_json() retries.
session = requests.Session()
session.headers.update({"Accept-Encoding": "identity", "Accept": "application/json"})


def get_json(url, params=None):
    for attempt in range(RETRIES):
        try:
            r = session.get(url, params=params, timeout=TIMEOUT)
            if attempt == 0:
                print(r.url)
            r.raise_for_status()
            return r.json()
        except requests.RequestException as e:
            if attempt == RETRIES - 1:
                raise
            print(f"retrying after {type(e).__name__}: {e}", file=sys.stderr)


def get_workers(args):
    data = get_json(
        f"{args.buildbot}/api/v2/workers", params=[("field", f) for f in FIELDS]
    )
    workers = data["workers"]
    if args.filter:
        workers = [w for w in workers if re.search(args.filter, w["name"])]
    return sorted(workers, key=lambda worker: worker["name"])


def print_workers(workers):
    for worker in workers:
        state = "paused" if worker["paused"] else "active"
        if worker["graceful"]:
            state += ", graceful shutdown"
        if not worker["connected_to"]:
            state += ", not connected"
        reason = worker.get("pause_reason")
        if worker["paused"] and reason:
            state += f": {reason}"
        print(f"{worker['name']} ({worker['workerid']}): {state}")


def control_worker(worker, action, args):
    data = {
        "jsonrpc": "2.0",
        "method": action,
        "params": {"reason": args.reason},
        "id": worker["workerid"],
    }
    r = session.post(
        f"{args.buildbot}/api/v2/workers/{worker['workerid']}",
        json=data,
        timeout=TIMEOUT,
    )
    r.raise_for_status()
    error = r.json().get("error")
    if error:
        raise RuntimeError(f"{worker['name']}: {error}")


def control_workers(workers, args):
    failed = 0
    for worker in workers:
        already = worker["paused"] if args.action == "pause" else not worker["paused"]
        if already and not args.force:
            print(f"skip {worker['name']} (already {args.action}d)")
            continue
        if args.dry_run:
            print(f"would {args.action} {worker['name']}")
            continue
        print(f"{args.action} {worker['name']}")
        try:
            control_worker(worker, args.action, args)
        except (requests.RequestException, RuntimeError) as e:
            print(f"ERROR: {e}", file=sys.stderr)
            failed += 1
    return failed


def main():
    parser = argparse.ArgumentParser(
        prog="pause-workers",
        description="Pause or unpause all Buildbot workers",
    )
    parser.add_argument(
        "action",
        choices=["pause", "unpause", "status"],
        help="action to perform on the workers ('status' only lists them)",
    )
    parser.add_argument(
        "-b", "--buildbot", default="http://buildbot.community.aws.openvpn.in:8010"
    )
    parser.add_argument(
        "-f",
        "--filter",
        help="only act on workers whose name matches this regular expression",
    )
    parser.add_argument(
        "-r",
        "--reason",
        default=f"paused by {os.environ.get('USER', 'unknown')} via pause-workers.py",
        help="reason recorded for the pause",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="also send the action to workers that are already in the target state",
    )
    parser.add_argument(
        "-n",
        "--dry-run",
        action="store_true",
        help="only show what would be done",
    )
    args = parser.parse_args()

    workers = get_workers(args)
    if not workers:
        print("no workers found", file=sys.stderr)
        return 1

    if args.action == "status":
        print_workers(workers)
        return 0

    failed = control_workers(workers, args)

    if not args.dry_run:
        print()
        print_workers(get_workers(args))

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())

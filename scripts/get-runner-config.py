#!/usr/bin/env python3
"""
Get runner configuration from tap.yaml.
Outputs JSON with runner settings for GitHub Actions.
"""

import sys
import json
import yaml
from pathlib import Path


def get_runner_config(tap_id):
    """Load runner configuration from tap.yaml."""
    tap_file = Path(f'taps/{tap_id}/tap.yaml')
    if not tap_file.exists():
        print(f"Error: {tap_file} not found", file=sys.stderr)
        sys.exit(1)

    with open(tap_file) as f:
        config = yaml.safe_load(f)

    runner = config.get('runner', {})
    extract = config.get('extract', {})

    # Defaults
    return {
        'server_type': runner.get('server_type', 'cx22'),
        'architecture': runner.get('architecture', 'x86'),
        'image': runner.get('image', 'ubuntu-24.04'),
        'location': runner.get('location', 'nbg1'),
        'timeout_minutes': extract.get('timeout_minutes', 30)
    }


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: get-runner-config.py <tap-id>", file=sys.stderr)
        sys.exit(1)

    tap_id = sys.argv[1]
    config = get_runner_config(tap_id)
    print(json.dumps(config))

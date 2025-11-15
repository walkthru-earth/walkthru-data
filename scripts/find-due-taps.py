#!/usr/bin/env python3
"""
Find taps that are due to run based on their tap.yaml schedules.

Outputs JSON array of tap IDs that should run now.
Example: ["re01", "cl01", "dm01"]
"""

import os
import json
import yaml
from datetime import datetime, timezone
from pathlib import Path


def parse_schedule(schedule_config):
    """Parse tap.yaml schedule configuration."""
    frequency = schedule_config.get('frequency', 'monthly')
    day = schedule_config.get('day', 1)
    hour, minute = map(int, schedule_config.get('time', '02:00').split(':'))
    enabled = schedule_config.get('enabled', True)

    return {
        'frequency': frequency,
        'day': day,
        'hour': hour,
        'minute': minute,
        'enabled': enabled
    }


def is_tap_due(tap_id, schedule, now=None):
    """Check if a tap is due to run based on its schedule."""
    if now is None:
        now = datetime.now(timezone.utc)

    if not schedule['enabled']:
        return False

    frequency = schedule['frequency']
    current_hour = now.hour
    current_day = now.day
    current_weekday = now.weekday()  # Monday=0, Sunday=6

    # Match schedule time (within current hour)
    if current_hour != schedule['hour']:
        return False

    if frequency == 'hourly':
        return True

    elif frequency == 'daily':
        return True  # Already matched the hour

    elif frequency == 'weekly':
        # Schedule day for weekly is weekday (0-6)
        return current_weekday == schedule['day']

    elif frequency == 'monthly':
        # Schedule day for monthly is day of month (1-31)
        return current_day == schedule['day']

    elif frequency == 'manual':
        # Only run on manual trigger
        return False

    else:
        print(f"Warning: Unknown frequency '{frequency}' for {tap_id}", file=sys.stderr)
        return False


def find_all_taps():
    """Find all taps in taps/ directory."""
    taps_dir = Path('taps')
    if not taps_dir.exists():
        return []

    return [d.name for d in taps_dir.iterdir() if d.is_dir() and (d / 'tap.yaml').exists()]


def load_tap_config(tap_id):
    """Load tap.yaml configuration."""
    tap_file = Path(f'taps/{tap_id}/tap.yaml')
    if not tap_file.exists():
        return None

    with open(tap_file) as f:
        return yaml.safe_load(f)


def main():
    """Main entry point."""
    now = datetime.now(timezone.utc)
    due_taps = []

    # Find all taps
    all_taps = find_all_taps()

    for tap_id in sorted(all_taps):
        try:
            config = load_tap_config(tap_id)
            if not config:
                continue

            schedule_config = config.get('schedule', {})
            schedule = parse_schedule(schedule_config)

            if is_tap_due(tap_id, schedule, now):
                due_taps.append(tap_id)
                print(f"✓ {tap_id} is due (frequency={schedule['frequency']}, "
                      f"time={schedule['hour']:02d}:{schedule['minute']:02d})",
                      file=sys.stderr)
            else:
                print(f"✗ {tap_id} not due yet (frequency={schedule['frequency']}, "
                      f"time={schedule['hour']:02d}:{schedule['minute']:02d})",
                      file=sys.stderr)

        except Exception as e:
            print(f"Error processing {tap_id}: {e}", file=sys.stderr)
            continue

    # Output JSON array
    print(json.dumps(due_taps))

    # Log summary
    print(f"\nFound {len(due_taps)} tap(s) due to run at {now.strftime('%Y-%m-%d %H:%M UTC')}",
          file=sys.stderr)


if __name__ == '__main__':
    import sys
    main()

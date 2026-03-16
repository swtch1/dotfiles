#!/usr/bin/env python3
"""Grade a spec file against eval_metadata.json assertions."""
import json
import re
import sys
from pathlib import Path

def grade(spec_path: str, metadata_path: str) -> dict:
    spec = Path(spec_path).read_text()
    meta = json.loads(Path(metadata_path).read_text())
    lines = spec.strip().split('\n')
    results = []

    for a in meta['assertions']:
        name = a['name']
        atype = a.get('type', '')
        passed = None
        evidence = ''

        if atype == 'contains_all':
            missing = [v for v in a['values'] if v.lower() not in spec.lower()]
            passed = len(missing) == 0
            evidence = f"Missing: {missing}" if missing else "All sections found"

        elif atype == 'regex_absent':
            pattern = a['pattern']
            matches = re.findall(pattern, spec)
            passed = len(matches) == 0
            evidence = f"Found {len(matches)} matches: {matches[:5]}" if matches else "No matches found (good)"

        elif atype == 'line_count':
            count = len(lines)
            passed = count <= a['max_lines']
            evidence = f"{count} lines (max {a['max_lines']})"

        elif atype == 'llm_judge':
            passed = None  # needs manual grading
            evidence = "Requires LLM judge"

        results.append({
            'text': name,
            'passed': passed,
            'evidence': evidence,
            'description': a.get('description', '')
        })

    return {
        'eval_name': meta['eval_name'],
        'spec_file': spec_path,
        'expectations': results,
        'auto_pass': sum(1 for r in results if r['passed'] is True),
        'auto_fail': sum(1 for r in results if r['passed'] is False),
        'needs_judge': sum(1 for r in results if r['passed'] is None),
        'total': len(results)
    }

if __name__ == '__main__':
    spec_path = sys.argv[1]
    meta_path = sys.argv[2]
    result = grade(spec_path, meta_path)
    print(json.dumps(result, indent=2))

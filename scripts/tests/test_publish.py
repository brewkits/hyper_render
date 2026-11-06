"""Exercise staging and failure handling with a fake Flutter (never uploads)."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'publish.sh'
PACKAGES = ['core', 'html', 'markdown', 'highlight', 'clipboard',
            'devtools', 'math', 'epub']


class PublishScriptTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='publish-test-')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name) / 'checkout'
        (self.root / 'scripts').mkdir(parents=True)
        shutil.copy2(SCRIPT, self.root / 'scripts/publish.sh')
        (self.root / '.pubignore').write_text('packages/\n')
        for directory in [self.root] + [
                self.root / 'packages' / f'hyper_render_{p}' for p in PACKAGES]:
            directory.mkdir(parents=True, exist_ok=True)
            (directory / 'lib').mkdir()
            (directory / 'lib/main.dart').write_text('// local source\n')
            (directory / 'pubspec.yaml').write_text(
                'name: example\nversion: 1.0.0\npublish_to: none\n'
                'dependency_overrides:\n  local:\n    path: ../local\n'
                '# retained top-level key below\n'
                'environment:\n  sdk: ">=3.5.0 <4.0.0"\n')
            (directory / 'pubspec_overrides.yaml').write_text('local overrides')
            (directory / 'build').mkdir()
            (directory / 'build/junk').write_text('generated')
        extension = self.root / 'packages/hyper_render_devtools/extension/devtools/build'
        extension.mkdir(parents=True)
        (extension / 'main.dart.js').write_text('// required published asset')
        self.before = {p: p.read_bytes() for p in self.root.rglob('pubspec*')}
        self.bin = Path(self.tmp.name) / 'bin'
        self.bin.mkdir()
        self.log = Path(self.tmp.name) / 'calls.jsonl'
        fake = f'#!{sys.executable}\n' + '''
import json, os, pathlib, sys
args = sys.argv[1:]
if args and args[0] == 'flutter': args = args[1:]
p = pathlib.Path.cwd()
with open(os.environ['CALL_LOG'], 'a') as f:
    f.write(json.dumps({'args': args, 'cwd': str(p)}) + '\\n')
if args[0] == 'analyze':
    sys.exit(0)
assert args[:2] == ['pub', 'publish'], args
assert '--dry-run' in args and '--force' not in args
assert not p.is_relative_to(pathlib.Path(os.environ['CHECKOUT']))
assert (p / 'lib/main.dart').exists()
assert not (p / 'pubspec_overrides.yaml').exists()
assert not (p / 'build/junk').exists()
spec = (p / 'pubspec.yaml').read_text()
assert 'dependency_overrides:' not in spec
assert 'publish_to: none' not in spec
assert 'environment:' in spec
if p.name == 'hyper_render_devtools':
    assert (p / 'extension/devtools/build/main.dart.js').exists()
if p.name == 'hyper_render':
    assert not (p / 'packages').exists()
if os.environ.get('FAIL_PUBLISH'):
    print(os.environ['FAIL_PUBLISH'])
    sys.exit(65)
print('Package has 0 warnings.')
'''
        for name in ['fvm', 'flutter']:
            tool = self.bin / name
            tool.write_text(fake)
            tool.chmod(0o755)

    def run_script(self, mode='dry-run', failure=''):
        env = dict(os.environ, PATH=f'{self.bin}:{os.environ["PATH"]}',
                   CALL_LOG=str(self.log), CHECKOUT=str(self.root),
                   FAIL_PUBLISH=failure)
        result = subprocess.run(['bash', str(self.root / 'scripts/publish.sh'), mode],
                                env=env, capture_output=True, text=True)
        for path, original in self.before.items():
            self.assertEqual(path.read_bytes(), original)
        calls = [json.loads(line) for line in self.log.read_text().splitlines()] \
            if self.log.exists() else []
        for call in calls:
            if call['args'][:2] == ['pub', 'publish']:
                self.assertFalse(Path(call['cwd']).exists(), 'staging was not cleaned')
        return result, calls

    def test_stages_all_packages_without_mutating_checkout(self):
        result, calls = self.run_script()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(sum(c['args'][0] == 'analyze' for c in calls), 9)
        self.assertEqual(sum(c['args'][:2] == ['pub', 'publish'] for c in calls), 9)

    def test_validation_failures_stop_and_clean_up(self):
        for message in ["doesn't match any versions", 'already exists', 'invalid archive']:
            with self.subTest(message=message):
                result, _ = self.run_script(failure=message)
                self.assertEqual(result.returncode, 65, result.stdout + result.stderr)
                self.assertNotIn('Dry-run complete', result.stdout)

    def test_unknown_mode_never_calls_flutter(self):
        result, calls = self.run_script(mode='publsih')
        self.assertEqual(result.returncode, 2)
        self.assertEqual(calls, [])


if __name__ == '__main__':
    unittest.main()

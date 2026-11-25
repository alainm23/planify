#!/usr/bin/env python3
"""Record opt-in GTK review workloads in a disposable generated fixture.

Run inside a fresh D-Bus/display session, e.g. dbus-run-session -- xvfb-run -a
python3 test/run-ui-review.py --fixture FIXTURE --output NEW_RUN --binary
BUILD/src/test-ui-review --schemas BUILD/test --scenario globals --heaptrack.
Requires xdotool and Pillow for actual pointer/keyboard input and screenshots.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import sqlite3
import subprocess as sp
import time


class Recording:
    def __init__(self, args):
        self.args = args
        self.root = args.output.resolve()
        fixture = args.fixture.resolve()
        manifest = json.loads((fixture / 'manifest.json').read_text())
        assert not manifest['network_accounts']
        db = fixture / 'data/io.github.alainm23.planify/database.db'
        assert hashlib.sha256(db.read_bytes()).hexdigest() == manifest['sha256']
        if self.root.exists():
            raise ValueError('Output already exists; preserve previous recordings.')
        shutil.copytree(fixture, self.root)
        self.recording = self.root / 'recording'
        self.recording.mkdir()
        shutil.copyfile(Path(__file__), self.recording / 'driver.py')
        source = args.binary.resolve().parents[2] / 'test/ui-review-scenarios.vala'
        shutil.copyfile(source, self.recording / 'harness.vala')
        (self.recording / 'build.json').write_text(json.dumps(dict(
            binary=str(args.binary.resolve()), binary_sha256=hashlib.sha256(args.binary.read_bytes()).hexdigest(),
            harness_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
            driver_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            fixture_sha256=manifest['sha256'], scenario=args.scenario, heaptrack=args.heaptrack,
            cycles=args.cycles, views=args.views, timeout=args.timeout), indent=2) + '\n')
        self.db = self.root / 'data/io.github.alainm23.planify/database.db'
        self.started = time.monotonic()
        self.events = []
        self.findings = []
        self.sequence = 0
        self.environment = dict(os.environ, XDG_DATA_HOME=str(self.root / 'data'),
            XDG_CONFIG_HOME=str(self.root / 'config'), XDG_CACHE_HOME=str(self.root / 'cache'),
            XDG_RUNTIME_DIR=str(self.root / 'runtime'), GTK_A11Y='none', NO_AT_BRIDGE='1',
            GSK_RENDERER='cairo', GSETTINGS_BACKEND='keyfile', GSETTINGS_SCHEMA_DIR=str(args.schemas.resolve()))
        (self.root / 'runtime').mkdir(mode=0o700)
        self.start()

    def record(self, event, **data):
        row = dict(seconds=time.monotonic() - self.started, event=event, **data)
        self.events.append(row)
        (self.recording / 'events.json').write_text(json.dumps(self.events, indent=2) + '\n')
        print(json.dumps(row), flush=True)

    def start(self, restart=False):
        if restart:
            self.environment['PLANIFY_REVIEW_RESTART'] = '1'
            (self.recording / 'response.json').unlink(missing_ok=True)
            (self.root / 'request.json').unlink(missing_ok=True)
        suffix = '-restart' if restart else ''
        self.log = (self.recording / f'application{suffix}.log').open('w')
        command = [str(self.args.binary.resolve())]
        if self.args.heaptrack:
            command = ['heaptrack', '--output', str(self.recording / ('heaptrack-review' + suffix))] + command
        self.process = sp.Popen(command, env=self.environment, stdout=self.log, stderr=sp.STDOUT)
        deadline = time.monotonic() + 180
        while time.monotonic() < deadline:
            if self.process.poll() is not None:
                raise RuntimeError(f'Application exited during startup: {self.process.returncode}')
            response = self.recording / 'response.json'
            if response.exists():
                state = json.loads(response.read_text())
                if state['id'] == 0:
                    self.state = state
                    self.record('ready', restart=restart, state=state)
                    return
            time.sleep(.1)
        raise TimeoutError('Application did not become ready')

    def rpc(self, command, *args, timeout=None):
        timeout = timeout or self.args.timeout
        self.sequence += 1
        request = dict(id=self.sequence, command=command, args=list(map(str, args)))
        tmp = self.root / 'request.tmp'
        tmp.write_text(json.dumps(request))
        tmp.replace(self.root / 'request.json')
        self.record('request', request=request)
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            path = self.recording / 'response.json'
            if path.exists():
                state = json.loads(path.read_text())
                if state['id'] == self.sequence:
                    self.state = state
                    self.record('response', state=state)
                    return state
            if self.process.poll() is not None:
                raise RuntimeError(f'Application exited during {command}: {self.process.returncode}')
            time.sleep(.1)
        raise TimeoutError(f'Application did not respond to {command}')

    def screenshot(self, name):
        from PIL import ImageGrab
        ImageGrab.grab().save(self.recording / (name + '.png'))

    def key(self, key):
        sp.run(['xdotool', 'key', '--clearmodifiers', key], check=True)
        time.sleep(.3)

    def type(self, text):
        sp.run(['xdotool', 'type', '--clearmodifiers', '--delay', '2', str(text)], check=True)

    def entry(self, *, text=None, id=None, type=None, last=False):
        matches = [w for w in self.state['widgets'] if (text is None or w['text'].replace('_', '') == text.replace('_', ''))
            and (id is None or w['id'] == id) and (type is None or w['type'] == type)
            and w['bounds'][2] > 2 and w['bounds'][3] > 2]
        if not matches:
            raise AssertionError(f'Widget absent: text={text!r}, id={id!r}, type={type!r}')
        return matches[-1] if last else matches[0]

    def point(self, entry, fx=.5, fy=.5):
        title = entry['window']
        ids = sp.check_output(['xdotool', 'search', '--onlyvisible', '--name', '^' + re.escape(title) + '$'], text=True).splitlines()
        window_id = ids[-1]
        x, y, w, h = entry['bounds']
        return window_id, round(x + w * fx), round(y + h * fy)

    def click(self, entry):
        window_id, x, y = self.point(entry)
        sp.run(['xdotool', 'windowfocus', '--sync', window_id, 'mousemove', '--window', window_id,
                str(x), str(y), 'click', '1'], check=True)
        self.record('pointer_click', widget=entry)
        time.sleep(.7)

    def choose_file(self, path):
        # Xvfb has no window manager: explicitly focus the native chooser before
        # typing, and accept using its actual button rather than a second Return.
        self.rpc('snapshot')
        title = next(w['window'] for w in self.state['widgets'] if w['window'] in ['Pick a File', 'Save a File'])
        window_id = sp.check_output(['xdotool', 'search', '--onlyvisible', '--name', '^' + re.escape(title) + '$'], text=True).splitlines()[-1]
        sp.run(['xdotool', 'windowfocus', '--sync', window_id], check=True)
        if title == 'Pick a File':
            matches = [w for w in self.state['widgets'] if w['window'] == title and w['type'] == 'GtkLabel' and w['text'] == Path(path).name]
            if matches:
                self.click(matches[0])
                self.rpc('snapshot')
                self.click(self.entry(text='_Open', type='GtkButton'))
                self.rpc('pause', 500)
                return
        self.key('ctrl+l')
        self.rpc('snapshot')
        entries = [w for w in self.state['widgets'] if w['window'] == title and w['type'] in ['GtkFileChooserEntry', 'GtkEntry', 'GtkText'] and w['bounds'][2] > 10]
        if not entries:
            raise AssertionError('No visible native chooser location entry')
        self.click(entries[0])
        self.rpc('fill-chooser', path)
        self.key('Return')
        self.rpc('pause', 500)
        if not self.state['widget_counts'].get('GtkFileChooserWidget', 0):
            return
        time.sleep(.5)
        self.screenshot('chooser-path-' + str(self.sequence))
        self.rpc('snapshot')
        self.click(self.entry(text='_Save' if title == 'Save a File' else '_Open', type='GtkButton'))
        self.rpc('pause', 500)

    def sql(self, statement, args=()):
        with sqlite3.connect(self.db) as db:
            return db.execute(statement, args).fetchall()

    def db_copy(self, name):
        target = self.recording / name
        with sqlite3.connect(self.db) as source, sqlite3.connect(target) as destination:
            source.backup(destination)
        return target

    def finish(self):
        self.rpc('quit')
        code = self.process.wait(timeout=60)
        self.log.close()
        assert code == 0, code
        self.record('finished', exit_code=code)

    def globals(self):
        assert self.sql('SELECT count(*) FROM Items')[0][0] == 5000
        views = ['inbox', 'today', 'scheduled', 'pinboard', 'labels', 'completed',
                 'tomorrow-view', 'anytime-view', 'repeating-view', 'unlabeled-view',
                 'all-items-view', 'priority-4', 'priority-3', 'priority-2', 'priority-1']
        if self.args.views:
            views = self.args.views.split(',')
        for cycle in range(1, self.args.cycles + 1):
            for view in views:
                self.record('global_begin', view=view, cycle=cycle)
                state = self.rpc('navigate', 'filter', view)
                state = self.rpc('pause', 1000)
                expected = 'project:synthetic-inbox' if view == 'inbox' else 'filter:' + view
                assert state['active_page'] == expected, (view, state['active_page'])
                self.screenshot(f'global-{cycle}-{view}')
                self.record('global_end', view=view, cycle=cycle, task_widgets=state['task_widgets'])
            self.rpc('navigate', 'filter', 'inbox')
            self.rpc('pause', 10000)
            self.record('global_cycle_idle', cycle=cycle)
        self.db_copy('final.db')
        assert self.sql('PRAGMA integrity_check') == [('ok',)]
        assert not self.sql('PRAGMA foreign_key_check')
        assert self.sql('SELECT count(*) FROM Items') == [(5000,)]

    def backup(self):
        self.db_copy('before.db')
        self.rpc('backup-page')
        self.click(self.entry(text='Create Backup', type='GtkButton'))
        self.rpc('pause', 1000)
        backups = sorted((self.root / 'data/io.github.alainm23.planify/backups').glob('*.json'))
        assert backups
        backup = backups[-1]
        reference = self.recording / 'reference-backup.json'
        shutil.copyfile(backup, reference)
        self.record('backup_created', path=str(backup), bytes=backup.stat().st_size)
        self.screenshot('backup-created')
        self.rpc('save-as', reference)
        self.screenshot('save-dialog')
        saved = self.recording / 'saved-copy.json'
        self.choose_file(saved)
        assert saved.read_bytes() == reference.read_bytes()
        self.record('save_dialog_success', bytes=saved.stat().st_size)
        self.rpc('save-as', reference)
        self.key('Escape')
        self.rpc('snapshot')
        self.record('save_dialog_cancelled')
        # Remove the source only after the dialog has opened: actual copy failure path.
        self.rpc('save-as', reference)
        missing = reference.with_suffix('.temporarily-missing')
        reference.rename(missing)
        destination = self.recording / 'missing-source-copy.json'
        self.choose_file(destination)
        missing.rename(reference)
        assert not destination.exists()
        self.rpc('snapshot')
        self.record('save_missing_source', destination_exists=False)
        self.screenshot('save-missing-source')
        # A regular file at the backup directory path causes a deterministic write error,
        # including when the test process runs as root.
        folder = backup.parent
        held = folder.with_name('backups-held')
        folder.rename(held)
        folder.write_text('Blocked backup directory for a disposable failure-path test.')
        self.rpc('snapshot')
        self.click(self.entry(text='Create Backup', type='GtkButton'))
        self.rpc('pause', 1000)
        self.screenshot('backup-write-failure')
        folder.unlink()
        held.rename(folder)
        self.record('backup_write_failure', backup_files=len(list(folder.glob('*.json'))))
        # Actual preference import caller, not only Backup.from_file.
        self.rpc('snapshot')
        self.click(self.entry(text='Import Backup', type='GtkButton'))
        self.screenshot('import-dialog')
        self.key('Escape')
        self.rpc('snapshot')
        self.screenshot('import-cancelled')
        self.record('import_cancelled')
        broken = self.recording / 'malformed.json'
        broken.write_text('{ invalid json')
        self.click(self.entry(text='Import Backup', type='GtkButton'))
        self.choose_file(broken)
        self.rpc('snapshot')
        self.screenshot('malformed-import')
        self.record('malformed_import')
        self.rpc('marker')
        assert self.sql("SELECT count(*) FROM Items WHERE id='review-restore-marker'") == [(1,)]
        self.click(self.entry(text='Import Backup', type='GtkButton'))
        self.choose_file(reference)
        self.rpc('snapshot')
        self.screenshot('restore-preview')
        self.click(self.entry(text='Restore Backup', type='WidgetsLoadingButton'))
        self.rpc('snapshot')
        self.screenshot('restore-confirmation')
        self.click(self.entry(text='Restore Backup', type='GtkButton', last=True))
        self.rpc('pause', 1500)
        self.screenshot('restore-completed')
        self.rpc('snapshot')
        self.click(self.entry(text='Restart Now', type='GtkButton'))
        self.rpc('pause', 2000)
        self.screenshot('restore-restarted-window')
        self.db_copy('after-window-restart.db')
        self.record('restore_window_restarted', task_count=self.sql('SELECT count(*) FROM Items')[0][0])
        self.finish()
        self.start(restart=True)
        self.rpc('pause', 1500)
        self.screenshot('restore-restarted-process')
        self.db_copy('after-process-restart.db')
        self.record('restore_process_restarted', task_count=self.sql('SELECT count(*) FROM Items')[0][0])
        comparisons = {}
        for name in ['after-window-restart.db', 'after-process-restart.db']:
            differences = {}
            with sqlite3.connect(self.recording / 'before.db') as before, sqlite3.connect(self.recording / name) as after:
                for table in ['Sources', 'Projects', 'Sections', 'Labels', 'Items', 'Reminders', 'Attachments']:
                    columns = [r[1] for r in before.execute('PRAGMA table_info(' + table + ')')]
                    original = {r[0]: r for r in before.execute('SELECT id,' + ','.join(c for c in columns if c != 'id') + ' FROM ' + table)}
                    restored = {r[0]: r for r in after.execute('SELECT id,' + ','.join(c for c in columns if c != 'id') + ' FROM ' + table)}
                    if original != restored:
                        differences[table] = dict(before=len(original), after=len(restored),
                            missing_ids=sorted(set(original)-set(restored)), extra_ids=sorted(set(restored)-set(original)),
                            changed_ids=sorted(k for k in original.keys() & restored.keys() if original[k] != restored[k]))
                assert after.execute('PRAGMA integrity_check').fetchall() == [('ok',)]
                assert not after.execute('PRAGMA foreign_key_check').fetchall()
            comparisons[name] = differences
        (self.recording / 'restore-comparison.json').write_text(json.dumps(comparisons, indent=2) + '\n')
        if any(comparisons.values()):
            self.findings.append('Restored database differs from the pre-export database; see restore-comparison.json')
        self.record('restore_verified', comparisons=comparisons)


    def drag(self, source, target, name):
        window_id, sx, sy = self.point(source, .55, .5)
        sp.run(['xdotool', 'windowfocus', '--sync', window_id, 'mousemove', '--window', window_id,
                str(sx), str(sy), 'mousedown', '1', 'mousemove', '--window', window_id, str(sx+20), str(sy)], check=True)
        time.sleep(.5)
        # Starting a task drag collapses its row. Re-read the target after that
        # animation; stale coordinates would hit the gap left by the source.
        self.rpc('snapshot')
        target = self.entry(id=target['id'], type=target['type'], last=target['type'] == 'LayoutsProjectRow')
        _, tx, ty = self.point(target, .6, .5)
        for step in range(1, 31):
            x = round(sx + (tx-sx) * step/30)
            y = round(sy + (ty-sy) * step/30)
            sp.run(['xdotool', 'mousemove', '--window', window_id, str(x), str(y)], check=True)
            time.sleep(.04)
        self.rpc('snapshot')
        target = self.entry(id=target['id'], type=target['type'], last=target['type'] == 'LayoutsProjectRow')
        _, tx, ty = self.point(target, .6, .5)
        sp.run(['xdotool', 'mousemove', '--window', window_id, str(tx), str(ty)], check=True)
        self.screenshot(name + '-dragging')
        sp.run(['xdotool', 'mouseup', '1'], check=True)
        time.sleep(1.5)
        self.record('pointer_drag', source=source, target=target)
        self.rpc('snapshot')
        self.screenshot(name + '-after')

    def dnd(self):
        self.rpc('seed-task', 'review-drag-parent', 'synthetic-inbox', 'child')
        self.rpc('seed-task', 'review-drag-target', 'synthetic-inbox')
        self.rpc('navigate', 'filter', 'inbox')
        self.rpc('focus-task', 'review-drag-parent')
        self.rpc('snapshot')
        self.rpc('observe-dnd')
        source = self.entry(id='review-drag-parent', type='LayoutsItemRow')
        target = self.entry(id='synthetic-project-1', type='LayoutsProjectRow', last=True)
        self.drag(source, target, 'task-to-sidebar-project')
        self.record('project_drop_database', rows=self.sql("SELECT id,project_id,parent_id FROM Items WHERE id LIKE 'review-drag-%'"))
        assert self.sql("SELECT project_id FROM Items WHERE id IN ('review-drag-parent','review-drag-parent-child')") == [('synthetic-project-1',), ('synthetic-project-1',)]
        moved = self.sql("SELECT project_id FROM Items WHERE id='review-drag-parent'")[0][0]
        self.rpc('navigate', 'project', moved)
        self.rpc('seed-task', 'review-drop-target', moved)
        self.rpc('focus-task', 'review-drop-target')
        self.rpc('snapshot')
        self.rpc('observe-dnd')
        self.drag(self.entry(id='review-drag-parent', type='LayoutsItemRow'),
                  self.entry(id='review-drop-target', type='LayoutsItemRow'), 'task-reparent')
        self.record('reparent_drop_database', rows=self.sql("SELECT id,project_id,parent_id FROM Items WHERE id LIKE 'review-%'"))
        assert self.sql("SELECT parent_id FROM Items WHERE id='review-drag-parent'") == [('review-drop-target',)]
        assert self.sql("SELECT parent_id FROM Items WHERE id='review-drag-parent-child'") == [('review-drag-parent',)]
        assert self.sql('PRAGMA integrity_check') == [('ok',)]
        assert not self.sql('PRAGMA foreign_key_check')
        self.db_copy('after-dnd.db')

    def backend(self):
        if not self.args.caldav_url or not self.args.caldav_url.startswith('http://127.0.0.1:'):
            raise ValueError('Use a disposable loopback CalDAV server.')
        self.rpc('backend-seed', self.args.caldav_url)
        self.rpc('seed-task', 'review-backend-parent', 'synthetic-inbox', 'child')
        self.rpc('cross-move', 'review-backend-parent', 'review-dav-a')
        rows = self.sql("SELECT id,content,project_id,parent_id,description,extra_data FROM Items WHERE content LIKE 'review-backend-%'")
        self.record('local_to_caldav', rows=rows)
        parents = [row for row in rows if row[1] == 'review-backend-parent' and row[2] == 'review-dav-a']
        assert len(parents) == 1, rows
        assert self.sql("SELECT description,priority FROM Items WHERE content='review-backend-parent' AND project_id='review-dav-a'") == [('Review payload preservation', 3)]
        assert len([r for r in rows if r[2] == 'review-dav-a']) == 2
        self.rpc('cross-move', parents[0][0], 'synthetic-project-1')
        rows = self.sql("SELECT id,content,project_id,parent_id,description,extra_data FROM Items WHERE content LIKE 'review-backend-%'")
        self.record('caldav_to_local', rows=rows)
        assert len([r for r in rows if r[2] == 'synthetic-project-1']) == 2, rows
        assert self.sql("SELECT description,priority FROM Items WHERE content='review-backend-parent' AND project_id='synthetic-project-1'") == [('Review payload preservation', 3)]
        assert not self.sql('PRAGMA foreign_key_check')
        self.db_copy('after-backend.db')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--fixture', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--binary', type=Path, required=True)
    parser.add_argument('--schemas', type=Path, required=True)
    parser.add_argument('--scenario', choices=['globals', 'backup', 'dnd', 'backend'], required=True)
    parser.add_argument('--caldav-url')
    parser.add_argument('--heaptrack', action='store_true')
    parser.add_argument('--timeout', type=int, default=900)
    parser.add_argument('--cycles', type=int, default=2)
    parser.add_argument('--views', help='Comma-separated global view IDs; default all 15')
    args = parser.parse_args()
    run = None
    try:
        run = Recording(args)
        getattr(run, args.scenario)()
        run.finish()
        run.record('completed_with_findings' if run.findings else 'success', scenario=args.scenario, findings=run.findings)
        return 0
    except Exception as error:
        if run:
            run.record('failed', error=str(error))
            run.screenshot('failure')
            if run.process.poll() is None:
                run.process.terminate()
                try: run.process.wait(timeout=30)
                except sp.TimeoutExpired: run.process.kill()
        raise


if __name__ == '__main__':
    raise SystemExit(main())

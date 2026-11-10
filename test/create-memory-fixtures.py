#!/usr/bin/env python3
"""Create disposable Planify profiling fixtures; never reads a user database."""
import argparse
import datetime as dt
import hashlib
import json
from pathlib import Path
import sqlite3

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--schema-from', type=Path, required=True,
                    help='Core-test scratch SQLite database; only schema definitions are read')
parser.add_argument('--output', type=Path, required=True, help='New output directory; existing paths are refused')
parser.add_argument('--anchor', type=dt.date.fromisoformat, default=dt.date.today())
args = parser.parse_args()
if args.output.exists():
    parser.error('Output already exists; choose a new directory to preserve existing runs.')
args.output.mkdir(parents=True)
with sqlite3.connect(args.schema_from.resolve().as_uri() + '?mode=ro', uri=True) as schema_db:
    statements = schema_db.execute("""
        SELECT sql FROM sqlite_master
        WHERE sql IS NOT NULL AND name NOT LIKE 'sqlite_%'
        ORDER BY CASE type WHEN 'table' THEN 0 WHEN 'index' THEN 1 ELSE 2 END, name
    """).fetchall()
    schema = '\n'.join(sql + ';' for (sql,) in statements)
    assert 'CREATE TABLE Items' in schema and 'CREATE TABLE Sources' in schema
anchor = args.anchor
stamp = f'{anchor.isoformat()}T12:00:00Z'

def iso(days):
    return (anchor + dt.timedelta(days=days)).isoformat()

def due_value(day, recurring=False):
    return json.dumps(dict(date=day, recurrence_string='every week' if recurring else '',
        timezone='', is_recurring=recurring, recurrency_type='3' if recurring else '6',
        recurrency_interval='1' if recurring else '0', recurrency_weeks='', recurrency_count='0',
        recurrency_end='', recurrency_last_day_of_month='false', recurrency_from_completion='false'),
        separators=(',', ':'))

for case, sizes in [('representative', [30, 86, 334]), ('stress', [50, 990, 990, 990, 990, 990])]:
    root = args.output / case
    data_dir = root / 'data' / 'io.github.alainm23.planify'
    data_dir.mkdir(parents=True)
    path = data_dir / 'database.db'
    db = sqlite3.connect(path)
    db.executescript(schema)
    db.execute('PRAGMA foreign_keys=ON')
    columns = {name: [(row[1], row[2]) for row in db.execute(f'PRAGMA table_info("{name}")')]
               for name in ['Sources', 'Projects', 'Sections', 'Labels', 'Items']}
    def insert(table, **values):
        fields = columns[table]
        unknown = set(values) - {name for name, _ in fields}
        assert not unknown, unknown
        row = [values.get(name, 0 if 'INT' in typ.upper() else '') for name, typ in fields]
        names = ','.join('"' + name + '"' for name, _ in fields)
        db.execute(f'INSERT INTO "{table}" ({names}) VALUES ({",".join("?" for _ in fields)})', row)

    insert('Sources', id='local', source_type='local', display_name='Synthetic profiling data',
           added_at=stamp, updated_at=stamp, is_visible=1, sync_server=0, data='')
    for number, name in enumerate(['Work', 'Personal', 'Planning', 'Follow-up', 'Research', 'Writing']):
        insert('Labels', id=f'synthetic-label-{number}', name=name, color='blue',
               item_order=number, backend_type='local', source_id='local', is_favorite=number < 2)

    for project_number, size in enumerate(sizes):
        project_id = 'synthetic-inbox' if project_number == 0 else f'synthetic-project-{project_number}'
        insert('Projects', id=project_id,
               name='Synthetic Inbox' if not project_number else f'Profiling Project {project_number:02}',
               color=['blue', 'green', 'orange', 'purple', 'red', 'teal'][project_number],
               backend_type='local', inbox_project=project_number == 0, child_order=project_number,
               is_favorite=project_number in [1, 2],
               view_style='board' if project_number == 2 else 'list', sort_order='asc',
               icon_style='progress', show_completed=1, source_id='local', sorted_by='manual',
               markdown_setting='global-default', description='Synthetic data for repeatable memory profiling.')
        if project_number:
            for section_number, name in enumerate(['Backlog', 'Next', 'In progress', 'Review', 'Done']):
                insert('Sections', id=f'{project_id}-section-{section_number}', name=name,
                       added_at=stamp, project_id=project_id, section_order=section_number, collapsed=1)
        for index in range(size):
            item_id = f'{project_id}-task-{index:04}'
            group = index // 10
            checked = group % 5 == 0
            parent = f'{project_id}-task-{index-1:04}' if index % 10 in [8, 9] else ''
            section_id = f'{project_id}-section-{group % 5}' if project_number else ''
            offset = ['', -7, 0, 14][group % 4]
            day = '' if offset == '' else iso(offset)
            recurring = index % 20 == 0 and bool(day) and not checked
            description = ('# Synthetic task\n\n- [ ] Reproduce navigation\n- [ ] Review retained allocations\n\n'
                           'Generated content only; includes café and quoted "examples".\n')
            if index % 10 == 0:
                description += 'Synthetic profiling notes. ' * 80
            payload_size = [1024, 4096, 16384][index % 3]
            calendar = (f'BEGIN:VCALENDAR\r\nVERSION:2.0\r\nBEGIN:VTODO\r\nUID:{item_id}\r\n'
                        f'SUMMARY:Synthetic task {index}\r\nDESCRIPTION:' + 'x' * payload_size +
                        '\r\nEND:VTODO\r\nEND:VCALENDAR\r\n')
            extra = json.dumps({'ical_url': f'https://calendar.example.invalid/{item_id}.ics',
                                'etag': f'"synthetic-{index}"', 'calendar-data': calendar}, separators=(',', ':'))
            label_ids = ';'.join(f'synthetic-label-{label}' for label in sorted({index % 6, (index + 2) % 6}))
            insert('Items', id=item_id, content=f'Synthetic task {index:04} — project {project_number}',
                   description=description, due=due_value(day, recurring),
                   added_at=f'{iso(-30 - index % 90)}T10:00:00Z',
                   updated_at=stamp, completed_at=f'{iso(-1 - index % 14)}T11:00:00Z' if checked else '',
                   project_id=project_id, section_id=section_id, parent_id=parent,
                   priority=1 + index % 4, child_order=index, checked=checked, collapsed=1,
                   pinned=not parent and not checked and index % 17 == 0,
                   labels=label_ids, extra_data=extra, item_type='task',
                   deadline_date=f'{iso(21)}T00:00:00Z' if index % 13 == 0 else '')
    db.execute("UPDATE OEvents SET event_date=?", (stamp,))
    db.commit()
    assert db.execute('PRAGMA integrity_check').fetchone() == ('ok',)
    assert not db.execute('PRAGMA foreign_key_check').fetchall()
    for query in [
        'SELECT count(*) FROM Items i LEFT JOIN Projects p ON i.project_id=p.id WHERE p.id IS NULL',
        "SELECT count(*) FROM Items i LEFT JOIN Items p ON i.parent_id=p.id WHERE i.parent_id!='' AND (p.id IS NULL OR p.project_id!=i.project_id OR p.section_id!=i.section_id)",
        "SELECT count(*) FROM Items i LEFT JOIN Sections s ON i.section_id=s.id WHERE i.section_id!='' AND s.id IS NULL",
        'SELECT count(*) FROM Sources WHERE sync_server!=0 OR source_type!=\'local\'',
    ]:
        assert db.execute(query).fetchone()[0] == 0, query
    counts = {table.lower(): db.execute(f'SELECT count(*) FROM {table}').fetchone()[0]
              for table in ['Sources', 'Projects', 'Sections', 'Items', 'Labels', 'Reminders', 'Attachments', 'OEvents']}
    counts.update(completed=db.execute('SELECT count(*) FROM Items WHERE checked=1').fetchone()[0],
                  subtasks=db.execute("SELECT count(*) FROM Items WHERE parent_id!=''").fetchone()[0],
                  payload_bytes=db.execute('SELECT sum(length(extra_data)) FROM Items').fetchone()[0])
    assert counts['items'] == sum(sizes)
    # Reject cycles and ensure all generated JSON and label references can be read.
    parents = dict(db.execute('SELECT id,parent_id FROM Items'))
    known_labels = {r[0] for r in db.execute('SELECT id FROM Labels')}
    for item_id, parent_id in parents.items():
        seen = {item_id}
        while parent_id:
            assert parent_id not in seen
            seen.add(parent_id)
            parent_id = parents[parent_id]
    for due, extra, labels in db.execute('SELECT due,extra_data,labels FROM Items'):
        json.loads(due)
        json.loads(extra)
        assert set(labels.split(';')) <= known_labels
    db.close()
    config_dir = root / 'config' / 'glib-2.0' / 'settings'
    config_dir.mkdir(parents=True)
    (config_dir / 'keyfile').write_text("[io/github/alainm23/planify]\nlocal-inbox-project-id='synthetic-inbox'\nhome-view='inbox'\nrun-in-background=false\nrun-on-startup=false\nbackup-automatic=false\nbackup-extra-folders=[]\n")
    (root / 'cache').mkdir()
    manifest = dict(case=case, anchor=anchor.isoformat(), schema_origin='Planify core-test scratch database schema only; no rows copied',
                    counts=counts, project_sizes=sizes, network_accounts=False,
                    sha256=hashlib.sha256(path.read_bytes()).hexdigest())
    (root / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps(dict(case=case, database=str(path.resolve()), **counts)))

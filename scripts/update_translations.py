#!/usr/bin/env python3
"""
Update translation files preserving complete header metadata.
"""
import subprocess
from pathlib import Path

def extract_full_header(po_file):
    """Extract complete header from PO file."""
    if not po_file.exists():
        return None
    
    header_lines = []
    in_header = False
    found_msgstr = False
    
    with open(po_file, 'r', encoding='utf-8') as f:
        for line in f:
            # Detect start of header (first msgid "")
            if line.strip() == 'msgid ""' and not in_header:
                in_header = True
                header_lines.append(line)
            # Inside header
            elif in_header:
                header_lines.append(line)
                # Detect msgstr of header
                if line.strip() == 'msgstr ""':
                    found_msgstr = True
                # Detect end of header (empty line after msgstr)
                elif found_msgstr and line.strip() == '':
                    break
    
    return ''.join(header_lines) if header_lines else None

def restore_full_header(po_file, old_header):
    """Restore complete header in PO file."""
    if not old_header:
        return
    
    with open(po_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Find where header ends in current file
    in_header = False
    found_msgstr = False
    header_end_idx = 0
    
    for idx, line in enumerate(lines):
        if line.strip() == 'msgid ""' and not in_header:
            in_header = True
        elif in_header:
            if line.strip() == 'msgstr ""':
                found_msgstr = True
            elif found_msgstr and line.strip() == '':
                header_end_idx = idx + 1
                break
    
    # Replace header with old one
    if header_end_idx > 0:
        new_content = old_header + ''.join(lines[header_end_idx:])
        with open(po_file, 'w', encoding='utf-8') as f:
            f.write(new_content)

def main():
    po_dir = Path('po')
    pot_file = po_dir / 'io.github.alainm23.planify.pot'
    
    # Generate POT file
    subprocess.run([
        'xgettext', '--files-from=po/POTFILES', '--directory=.',
        '--output=po/io.github.alainm23.planify.pot',
        '--from-code=UTF-8', '--keyword=_', '--keyword=N_', '--keyword=C_:1c,2'
        '--package-name=io.github.alainm23.planify'
    ], check=True)
    
    # Update PO files
    with open(po_dir / 'LINGUAS', 'r') as f:
        languages = f.read().strip().split()
    
    for lang in languages:
        po_file = po_dir / f'{lang}.po'
        if not po_file.exists():
            continue
        
        # Save old header
        old_header = extract_full_header(po_file)
        
        # Update PO file
        subprocess.run([
            'msgmerge', '--update', '--no-fuzzy-matching',
            '--backup=none',
            str(po_file), str(pot_file)
        ], check=True)
        
        # Restore old header
        restore_full_header(po_file, old_header)

if __name__ == '__main__':
    main()

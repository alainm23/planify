#!/usr/bin/env python3
"""
Update translation files preserving POT-Creation-Date.
"""
import subprocess
import re
from pathlib import Path

def get_pot_date(po_file):
    """Extract POT-Creation-Date value from PO file."""
    with open(po_file, 'r', encoding='utf-8') as f:
        for line in f:
            if 'POT-Creation-Date:' in line:
                # Extract just the date value
                match = re.search(r'POT-Creation-Date: ([^\\]+)', line)
                if match:
                    return match.group(1)
    return None

def restore_pot_date(po_file, old_date):
    """Restore POT-Creation-Date value in PO file."""
    if not old_date:
        return
    
    with open(po_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace only the date value, keeping the line format
    content = re.sub(
        r'("POT-Creation-Date: )[^\\]+(\\n")',
        r'\g<1>' + old_date + r'\g<2>',
        content
    )
    
    with open(po_file, 'w', encoding='utf-8') as f:
        f.write(content)

def main():
    po_dir = Path('po')
    pot_file = po_dir / 'io.github.alainm23.planify.pot'
    
    # Generate POT file
    subprocess.run([
        'xgettext', '--files-from=po/POTFILES', '--directory=.',
        '--output=po/io.github.alainm23.planify.pot',
        '--from-code=UTF-8', '--keyword=_', '--keyword=N_',
        '--package-name=io.github.alainm23.planify'
    ], check=True)
    
    # Update PO files
    with open(po_dir / 'LINGUAS', 'r') as f:
        languages = f.read().strip().split()
    
    for lang in languages:
        po_file = po_dir / f'{lang}.po'
        if not po_file.exists():
            continue
        
        # Save old POT-Creation-Date
        old_pot_date = get_pot_date(po_file)
        
        # Update PO file
        subprocess.run([
            'msgmerge', '--update', '--no-fuzzy-matching',
            '--backup=none',
            str(po_file), str(pot_file)
        ], check=True)
        
        # Restore old POT-Creation-Date
        restore_pot_date(po_file, old_pot_date)

if __name__ == '__main__':
    main()

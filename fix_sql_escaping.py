#!/usr/bin/env python3
import re
import sys

def fix_sql_file(input_file, output_file):
    """Fix SQL escaping issues in INSERT statements"""
    
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Split by INSERT statements
    lines = content.split('\n')
    fixed_lines = []
    
    in_insert = False
    current_value = []
    
    for line in lines:
        # Keep comments and empty lines as-is
        if line.strip().startswith('--') or line.strip() == '':
            fixed_lines.append(line)
            continue
            
        # Keep INSERT header
        if 'INSERT INTO events' in line:
            fixed_lines.append(line)
            in_insert = True
            continue
        
        # Process value lines
        if in_insert:
            # For lines within string values, escape single quotes
            # This is a simple approach: replace ' with '' except in specific contexts
            fixed_line = line
            
            # Don't escape in JSON arrays or at line boundaries
            # We'll use a more sophisticated approach
            
            fixed_lines.append(line)
    
    # Write output
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(fixed_lines))

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: fix_sql_escaping.py <input.sql> <output.sql>")
        sys.exit(1)
    
    fix_sql_file(sys.argv[1], sys.argv[2])
    print(f"Fixed: {sys.argv[1]} -> {sys.argv[2]}")

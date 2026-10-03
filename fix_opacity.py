import os
import re

def find_matching_paren(s, start_idx):
    # start_idx points to the '(' of withOpacity(
    count = 0
    for i in range(start_idx, len(s)):
        if s[i] == '(':
            count += 1
        elif s[i] == ')':
            count -= 1
            if count == 0:
                return i
    return -1

def replace_with_opacity(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    modified = False
    start_pos = 0
    
    while True:
        idx = content.find('.withOpacity(', start_pos)
        if idx == -1:
            break
        
        # We found '.withOpacity('
        # The opening parenthesis is at idx + 12
        open_paren_idx = idx + 12
        close_paren_idx = find_matching_paren(content, open_paren_idx)
        
        if close_paren_idx != -1:
            # Extract the content inside the parentheses
            inside_content = content[open_paren_idx + 1:close_paren_idx]
            old_str = content[idx:close_paren_idx + 1]
            new_str = f'.withValues(alpha: {inside_content})'
            
            # Replace in content
            content = content[:idx] + new_str + content[close_paren_idx + 1:]
            modified = True
            # Move start_pos past the replaced part to avoid infinite loop
            start_pos = idx + len(new_str)
        else:
            # If no matching paren found, skip this one
            start_pos = idx + 13
            
    if modified:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed withOpacity in: {file_path}")
        return 1
    return 0

def main():
    lib_dir = r"E:\flutter projects\saloon_app\lib"
    fixed_count = 0
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                full_path = os.path.join(root, file)
                fixed_count += replace_with_opacity(full_path)
    print(f"Total files fixed: {fixed_count}")

if __name__ == '__main__':
    main()

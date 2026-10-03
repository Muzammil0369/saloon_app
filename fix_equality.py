import os
import re

def fix_file_equality(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    
    # Replace Get.find<LanguageController>().languageCode ==
    content = re.sub(
        r'(\bGet\.find<LanguageController>\(\)\.languageCode\b)(?!\.value)\s*==',
        r'Get.find<LanguageController>().languageCode.value ==',
        content
    )
    
    # Replace languageController.languageCode ==
    content = re.sub(
        r'(\blanguageController\.languageCode\b)(?!\.value)\s*==',
        r'languageController.languageCode.value ==',
        content
    )
    
    # Replace langCode ==
    content = re.sub(
        r'(\blangCode\b)(?!\.value)\s*==',
        r'langCode.value ==',
        content
    )
    
    if content != original:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed equality in: {file_path}")
        return 1
    return 0

def main():
    lib_dir = r"E:\flutter projects\saloon_app\lib"
    fixed_count = 0
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                full_path = os.path.join(root, file)
                fixed_count += fix_file_equality(full_path)
    print(f"Total files fixed for equality: {fixed_count}")

if __name__ == '__main__':
    main()

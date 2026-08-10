import os
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Skip if already imported
    if 'flutter_screenutil' not in content:
        # Add import after first flutter import
        content = re.sub(
            r"(import 'package:flutter/material.dart';)",
            r"\1\nimport 'package:flutter_screenutil/flutter_screenutil.dart';",
            content
        )

    # fontSize: 18 -> fontSize: 18.sp
    content = re.sub(r'fontSize:\s*([0-9.]+)(?![\.a-zA-Z])', r'fontSize: \1.sp', content)
    
    # SizedBox(height: 10) -> SizedBox(height: 10.h)
    content = re.sub(r'height:\s*([0-9.]+)(?![\.a-zA-Z])', r'height: \1.h', content)
    
    # SizedBox(width: 10) -> SizedBox(width: 10.w)
    content = re.sub(r'width:\s*([0-9.]+)(?![\.a-zA-Z])', r'width: \1.w', content)
    
    # BorderRadius.circular(10) -> BorderRadius.circular(10.r)
    content = re.sub(r'circular\(([0-9.]+)\)', r'circular(\1.r)', content)
    
    # EdgeInsets.all(10) -> EdgeInsets.all(10.w)
    content = re.sub(r'EdgeInsets\.all\(([0-9.]+)\)', r'EdgeInsets.all(\1.w)', content)
    
    # EdgeInsets.symmetric(horizontal: 10, vertical: 10) -> horizontal: 10.w, vertical: 10.h
    content = re.sub(r'horizontal:\s*([0-9.]+)(?![\.a-zA-Z])', r'horizontal: \1.w', content)
    content = re.sub(r'vertical:\s*([0-9.]+)(?![\.a-zA-Z])', r'vertical: \1.h', content)
    
    # EdgeInsets.only(...)
    content = re.sub(r'top:\s*([0-9.]+)(?![\.a-zA-Z])', r'top: \1.h', content)
    content = re.sub(r'bottom:\s*([0-9.]+)(?![\.a-zA-Z])', r'bottom: \1.h', content)
    content = re.sub(r'left:\s*([0-9.]+)(?![\.a-zA-Z])', r'left: \1.w', content)
    content = re.sub(r'right:\s*([0-9.]+)(?![\.a-zA-Z])', r'right: \1.w', content)

    # Icon(..., size: 24) -> size: 24.sp (or .w)
    # Actually size is usually width, let's use .sp for icons to match font scaling or .w for physical size. We'll use .w
    content = re.sub(r'size:\s*([0-9.]+)(?![\.a-zA-Z])', r'size: \1.w', content)

    with open(filepath, 'w') as f:
        f.write(content)

def main():
    screens_dir = '/Users/mac/Documents/GBAT-DEV/passe_voyage/lib/presentation/screens'
    for root, dirs, files in os.walk(screens_dir):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                process_file(filepath)
                
    widgets_dir = '/Users/mac/Documents/GBAT-DEV/passe_voyage/lib/presentation/widgets'
    for root, dirs, files in os.walk(widgets_dir):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                process_file(filepath)

if __name__ == '__main__':
    main()

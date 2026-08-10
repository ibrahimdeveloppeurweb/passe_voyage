import os
import re

def remove_invalid_consts(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Expanding the list of targets
    targets = [
        'SizedBox', 'EdgeInsets', 'TextStyle', 'Padding', 'Text', 'Icon',
        'BorderSide', 'UnderlineInputBorder', 'BorderRadius', 'Radius',
        'BoxDecoration', 'OutlineInputBorder', 'Container', 'Column', 'Row',
        'Divider', 'SliverToBoxAdapter', 'Expanded', 'RoundedRectangleBorder', 'Center'
    ]
    
    pattern = r'const\s+(' + '|'.join(targets) + r')\b'
    content = re.sub(pattern, r'\1', content)

    # Replace 'const [' with '['
    content = re.sub(r'const\s+\[', r'[', content)
    
    # Also 'const <Widget>['
    content = re.sub(r'const\s+<[^>]+>\[', r'[', content)

    # Some consts might be left because they are multiline or we missed the target class.
    # We can also do a broader regex: any "const " before a capitalized word where .h or .w etc is used.
    # But let's see if this fixes the remaining ones.

    with open(filepath, 'w') as f:
        f.write(content)

def main():
    screens_dir = '/Users/mac/Documents/GBAT-DEV/passe_voyage/lib/presentation/screens'
    for root, dirs, files in os.walk(screens_dir):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                remove_invalid_consts(filepath)
                
    widgets_dir = '/Users/mac/Documents/GBAT-DEV/passe_voyage/lib/presentation/widgets'
    for root, dirs, files in os.walk(widgets_dir):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                remove_invalid_consts(filepath)

if __name__ == '__main__':
    main()

import json
import os

file_path = '/home/momo/Bureau/semi-projets/algo/pseudo_code/assets/challenges.json'

with open(file_path, 'r', encoding='utf-8') as f:
    challenges = json.load(f)

for i, challenge in enumerate(challenges):
    index = i + 1
    
    # Update title to ensure consistent "Exercice X: " prefix
    title = challenge.get('title', '')
    if 'Exercice' in title and ':' in title:
        _, rest = title.split(':', 1)
        challenge['title'] = f"Exercice {index}:{rest}"
    else:
        challenge['title'] = f"Exercice {index}: {title}"
    
    # Update difficulty
    if index <= 50:
        challenge['difficulty'] = "Easy"
    elif index <= 100:
        challenge['difficulty'] = "Medium"
    else:
        challenge['difficulty'] = "Hard"

with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(challenges, f, ensure_ascii=False, indent=2)

print(f"Organized {len(challenges)} challenges.")

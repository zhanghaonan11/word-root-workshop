import re
import eng_to_ipa as ipa
from pathlib import Path

FILE_PATH = Path(__file__).resolve().parents[1] / 'ios' / 'data' / 'wordData.js'

with open(FILE_PATH, 'r', encoding='utf-8') as f:
    content = f.read()

# First we need to undo the previous incorrect insertion which put phonetic inside breakdown
content = re.sub(r",\s*phonetic:\s*'[^']*'\s*\}", " }", content)

def process_example(match):
    block = match.group(0)
    word_match = re.search(r"word:\s*'([^']+)'", block)
    if not word_match:
        return block
    
    word = word_match.group(1)
    phonetic_ipa = ipa.convert(word)
    phonetic_str = ""
    if phonetic_ipa and not phonetic_ipa.endswith('*'):
        phonetic_str = f"/{phonetic_ipa}/"
        
    # Inject at the root of the object right after the word field
    return re.sub(r"word:\s*'[^']+'", f"word: '{word}', phonetic: '{phonetic_str}'", block)

new_content = re.sub(r'\{\s*word:\s*\'[^\']+\'.*?\}', process_example, content, flags=re.DOTALL)

with open(FILE_PATH, 'w', encoding='utf-8') as f:
    f.write(new_content)

print(f"Finished processing {FILE_PATH}")

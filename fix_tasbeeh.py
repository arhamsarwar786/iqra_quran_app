import json

with open('assets/json_data/hajj.json', 'r') as f:
    hajj_data = json.load(f)

new_items = []
# Add Talbiyah
talbiyah = hajj_data['talbiyah']
new_items.append({
    "Arabic": talbiyah['arabic'],
    "Transliteration": talbiyah['transliteration'],
    "English Meaning": talbiyah['translation'],
    "Urdu Meaning": "میں حاضر ہوں اے اللہ، میں حاضر ہوں۔ تیرا کوئی شریک نہیں، میں حاضر ہوں۔ بیشک تمام تعریفیں، نعمتیں اور بادشاہی تیرے ہی لیے ہے، تیرا کوئی شریک نہیں۔"
})

# Add Takbeerat
takbeer = hajj_data['takbeerat'][0]
new_items.append({
    "Arabic": takbeer['arabic'],
    "Transliteration": takbeer['transliteration'],
    "English Meaning": takbeer['translation'],
    "Urdu Meaning": "اللہ سب سے بڑا ہے، اللہ سب سے بڑا ہے۔ اللہ کے سوا کوئی معبود نہیں، اور اللہ سب سے بڑا ہے، اللہ سب سے بڑا ہے، اور تمام تعریفیں اللہ کے لیے ہیں۔"
})

with open('assets/json_data/tasbeeh.json', 'r') as f:
    tasbeeh_data = json.load(f)

# Combine, and re-assign "No"
combined = new_items + tasbeeh_data
for i, item in enumerate(combined):
    item['No'] = str(i + 1)

with open('assets/json_data/tasbeeh.json', 'w') as f:
    json.dump(combined, f, ensure_ascii=False, indent=2)

print("Tasbeeh updated.")

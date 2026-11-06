from pathlib import Path
from PIL import Image
from docx import Document
ROOT=Path(__file__).resolve().parents[2]/'store_listing'
for name,limit in [('title.txt',30),('short-description.txt',80),('full-description.txt',4000),('release-notes.txt',500)]:
 text=(ROOT/'en-US'/name).read_text().strip()
 assert 0<len(text)<=limit,(name,len(text),limit)
 print(f'{name}: {len(text)}/{limit} characters')
for name,size in [('app-icon-512.png',(512,512)),('feature-graphic-1024x500.png',(1024,500))]:
 im=Image.open(ROOT/'graphics'/name); assert im.size==size and im.mode=='RGB'
mockups=sorted((ROOT/'graphics/mockups').glob('*.png')); assert len(mockups)==8
for p in mockups:
 im=Image.open(p); assert im.size==(1080,1920) and im.mode=='RGB'
doc=Document(ROOT/'privacy/PriceDiary-Privacy-Policy.docx')
assert 'PriceDiary Privacy Policy' in doc.paragraphs[0].text
assert any('privacy@example.invalid' in p.text for p in doc.paragraphs)
print('PASS: asset sizes, image modes, eight draft mockups and readable Word document.')
print('PUBLISHING BLOCKERS: dummy contact email, missing public policy URL, runtime screenshots required.')

"""Regenerate Word/HTML policy from Markdown. Requires python-docx."""
from pathlib import Path
import html
from docx import Document
from docx.shared import Inches, Pt, RGBColor
ROOT=Path(__file__).resolve().parents[2]
folder=ROOT/'store_listing/privacy'
source=(folder/'privacy-policy.md').read_text()
doc=Document()
section=doc.sections[0]; section.top_margin=Inches(.75); section.bottom_margin=Inches(.75)
style=doc.styles['Normal']; style.font.name='Calibri'; style.font.size=Pt(11)
style.paragraph_format.space_after=Pt(9)
for name in ['Title','Heading 1','Heading 2']:
 doc.styles[name].font.color.rgb=RGBColor.from_string('007F73')
html_parts=[]
for block in source.strip().split('\n\n'):
 if block.startswith('# '):
  doc.add_heading(block[2:],0); html_parts.append('<h1>'+html.escape(block[2:])+'</h1>')
 elif block.startswith('## '):
  doc.add_heading(block[3:],1); html_parts.append('<h2>'+html.escape(block[3:])+'</h2>')
 else:
  doc.add_paragraph(block); html_parts.append('<p>'+html.escape(block)+'</p>')
section.footer.paragraphs[0].text='PriceDiary | Privacy Policy | November 6, 2026'
doc.core_properties.title='PriceDiary Privacy Policy'
doc.core_properties.subject='Offline price diary privacy practices'
doc.core_properties.author='PriceDiary development team'
doc.save(folder/'PriceDiary-Privacy-Policy.docx')
(folder/'privacy-policy.html').write_text('''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>PriceDiary Privacy Policy</title><style>body{font:17px/1.65 system-ui,sans-serif;max-width:820px;margin:40px auto;padding:0 24px;color:#173d37}h1,h2{color:#007f73}h2{margin-top:1.8em}</style></head><body><main>'''+''.join(html_parts)+'</main></body></html>')
print('Generated DOCX and HTML privacy policy.')

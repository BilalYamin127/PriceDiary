"""Rebuild listing compositions and launcher sizes. Requires Pillow and python-docx.
Phone images are illustrative mockups, never captured runtime screenshots.
Run from the repository root: python3 store_listing/source/create_assets.py
"""
from pathlib import Path
import json, textwrap
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'store_listing/graphics'
TEAL='#007F73'; INK='#123A37'; MUTED='#607671'; ORANGE='#FFB24A'; BG='#F3F8F5'
FONT='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
BOLD='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
def font(size,bold=False): return ImageFont.truetype(BOLD if bold else FONT,size)
def txt(d,xy,s,size=24,color=INK,bold=False): d.text(xy,s,font=font(size,bold),fill=color)
def rounded(d,box,color,r=22,outline=None): d.rounded_rectangle(box,radius=r,fill=color,outline=outline,width=2)
master=Image.open(ROOT/'store_listing/source/icon-master.png').convert('RGB')
master.resize((512,512),Image.Resampling.LANCZOS).save(OUT/'app-icon-512.png')
# Export regular Android launchers and the other generated platform icon sizes.
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
 master.resize((size,size),Image.Resampling.LANCZOS).save(ROOT/f'android/app/src/main/res/mipmap-{density}/ic_launcher.png')
for platform in ['ios','macos']:
 p=ROOT/f'{platform}/Runner/Assets.xcassets/AppIcon.appiconset'
 for asset in json.loads((p/'Contents.json').read_text())['images']:
  if 'filename' not in asset: continue
  n=round(float(asset['size'].split('x')[0])*float(asset.get('scale','1x').rstrip('x')))
  master.resize((n,n),Image.Resampling.LANCZOS).save(p/asset['filename'])
for n in [192,512]:
 for name in [f'Icon-{n}.png',f'Icon-maskable-{n}.png']:
  master.resize((n,n),Image.Resampling.LANCZOS).save(ROOT/'web/icons'/name)
master.resize((32,32),Image.Resampling.LANCZOS).save(ROOT/'web/favicon.png')
master.save(ROOT/'windows/runner/resources/app_icon.ico',sizes=[(16,16),(32,32),(48,48),(64,64),(128,128),(256,256)])
# Feature graphic: exactly 1024 x 500, opaque PNG.
im=Image.new('RGB',(1024,500),TEAL); d=ImageDraw.Draw(im)
d.ellipse((720,-180,1230,330),fill='#098E80'); d.ellipse((780,340,1100,660),fill='#169B89')
im.paste(master.resize((150,150)),(66,70))
txt(d,(66,246),'PriceDiary',58,'white',True)
txt(d,(68,331),'Remember prices.',29,'white'); txt(d,(68,373),'Compare with confidence.',29,'white')
rounded(d,(625,80,955,420),'#F1FAF6',30)
txt(d,(654,110),'YOUR PRICE DIARY',17,TEAL,True)
for y,shop,price in [(166,'Local Store','$2.40'),(238,'City Market','$2.65'),(310,'Supermarket','$2.80')]:
 rounded(d,(646,y,934,y+58),'#DDEFE7' if y==166 else '#FFFFFF',14)
 txt(d,(658,y+18),shop,17); txt(d,(850,y+18),price,18,TEAL,True)
txt(d,(656,386),'Illustrative prices',14,MUTED)
im.save(OUT/'feature-graphic-1024x500.png')
# A consistent eight-frame editorial storyboard based on implemented screens.
slides=[
 ('01-dashboard','Every price,','one personal diary.','Home dashboard','Your personal memory for everyday prices'),
 ('02-products','Find it faster.','Remember the details.','Products','Track the exact product and package size'),
 ('03-product-form','Track the product.','Keep the package size.','New product','Names, brands, units and notes'),
 ('04-record-price','Saw a price?','Save the observation.','Record a price','A fresh entry keeps your history intact'),
 ('05-comparison','Compare shops.','Check the dates.','Whole milk','Latest observed prices, in one currency'),
 ('06-history','See what changed.','Visit by visit.','Price history','Compare visits at the same shop'),
 ('07-chart','Turn observations','into a clear trend.','Price chart','Filter by shop, currency and dates'),
 ('08-backup','Your diary.','Ready to move with you.','Settings','Offline storage. Full backup and restore.'),
]
for index,(slug,h1,h2,title,sub) in enumerate(slides):
 im=Image.new('RGB',(1080,1920),BG); d=ImageDraw.Draw(im)
 d.ellipse((850,-180,1250,240),fill='#DCEFE7')
 txt(d,(72,68),'PriceDiary',27,TEAL,True)
 txt(d,(72,145),h1,56,INK,True); txt(d,(72,222),h2,49,INK,True)
 txt(d,(74,322),'Personal price tracking. Completely offline.',23,MUTED)
 # Deliberately visible draft label; these are not runtime screenshots.
 rounded(d,(55,420,1025,1800),'#133B36',56)
 rounded(d,(69,434,1011,1786),'#FAFCFA',45)
 txt(d,(108,465),'9:41',21,INK,True); txt(d,(855,465),'LTE  100%',19)
 txt(d,(108,535),title,38,INK,True)
 y=601
 for line in textwrap.wrap(sub,54): txt(d,(108,y),line,22,MUTED); y+=31
 def card(top,primary,secondary='',price=None,fill='white',height=134):
  rounded(d,(106,top,974,top+height),fill,22,outline='#DEE9E4')
  txt(d,(134,top+25),primary,26,INK,True)
  if secondary: txt(d,(134,top+72),secondary,21,MUTED)
  if price: txt(d,(750,top+30),price,28,TEAL,True)
 def field(top,label,value):
  txt(d,(112,top),label,20,MUTED)
  rounded(d,(108,top+34,972,top+114),'white',14,outline='#A8BCB5')
  txt(d,(132,top+57),value,25)
 def button(top,label):
  rounded(d,(108,top,972,top+78),TEAL,38); txt(d,(150,top+22),label,25,'white',True)
 if index==0:
  for x,n,label in [(108,'8','Products'),(400,'3','Shops'),(692,'24','Observations')]:
   rounded(d,(x,705,x+278,865),'#E0F0E8',22); txt(d,(x+24,726),n,48,TEAL,True); txt(d,(x+24,803),label,20)
  button(895,'+  Record a price'); txt(d,(110,1020),'Recently updated',27,INK,True)
  card(1080,'Whole milk','1 L • Local Store • Nov 6, 2026','$2.40')
  card(1232,'Rice','1 kg • City Market • Nov 5, 2026','$1.80')
  txt(d,(110,1420),'Price changes',27,INK,True)
  card(1480,'Whole milk','Local Store • previous observation: $2.30','+4.3%',fill='#FFF0DA')
 elif index==1:
  field(688,'Search products','milk'); txt(d,(110,850),'All categories     All shops     Sort: Name',23,TEAL)
  card(920,'Whole milk','Dairy Farm • 1 L','$2.40'); card(1080,'Whole milk','Dairy Farm • 500 ml','$1.30')
  txt(d,(110,1290),'Exact packages. Dated observations.',24,MUTED)
 elif index==2:
  for y,label,value in [(680,'Product name','Whole milk'),(825,'Brand (optional)','Dairy Farm'),(970,'Category','Groceries'),(1115,'Package quantity','1'),(1260,'Unit','L'),(1405,'Notes (optional)','Regular weekly purchase')]: field(y,label,value)
  button(1580,'Save product')
 elif index==3:
  for y,label,value in [(680,'Product','Whole milk · 1 L'),(825,'Shop','Local Store'),(970,'Observed price','2.40'),(1115,'Currency code','USD'),(1260,'Observation date','Nov 6, 2026'),(1405,'Notes (optional)','Shelf price')]: field(y,label,value)
  button(1580,'Save observation')
 elif index==4:
  txt(d,(110,698),'Compare        History        Chart',25,TEAL,True)
  card(774,'Lowest latest observation: $2.40','Spread: $0.40',fill='#DDEFE7',height=140)
  card(945,'Local Store','Observed Nov 6, 2026 • Lowest','$2.40')
  card(1100,'City Market','Observed Nov 5, 2026','$2.65')
  card(1255,'Supermarket','Observed Nov 4, 2026 • Highest','$2.80')
  for i,line in enumerate(['These are dated observations.','Actual shop prices may have changed.']): txt(d,(116,1460+i*38),line,24,MUTED)
  button(1580,'+  Add price')
 elif index==5:
  card(715,'$2.40 · Local Store','Nov 6, 2026 • Change +$0.10 (+4.3%)',height=156)
  card(900,'$2.30 · Local Store','Oct 23, 2026 • Change -$0.20 (-8.0%)',height=156)
  card(1085,'$2.50 · Local Store','Oct 9, 2026 • First observation',height=156)
  rounded(d,(380,1280,966,1505),'#E5F1EB',20)
  txt(d,(418,1310),'Record again',27,TEAL,True); txt(d,(418,1370),'Edit observation',24); txt(d,(418,1430),'Delete observation',24)
  txt(d,(112,1570),'Each visit stays in your history.',23,MUTED)
 elif index==6:
  field(684,'Shop','Local Store'); field(830,'Date range','Oct 9 – Nov 6, 2026')
  rounded(d,(106,1030,974,1490),'white',22,outline='#DEE9E4')
  for y,label in [(1100,'2.50'),(1200,'2.40'),(1300,'2.30')]:
   d.line((210,y,920,y),fill='#DFE9E4',width=2); txt(d,(126,y-12),label,19,MUTED)
  d.line([(250,1100),(540,1300),(860,1200)],fill=TEAL,width=7)
  for x,y in [(250,1100),(540,1300),(860,1200)]: d.ellipse((x-11,y-11,x+11,y+11),fill=ORANGE)
  for x,label in [(220,'Oct 9'),(495,'Oct 23'),(815,'Nov 6')]: txt(d,(x,1400),label,20,MUTED)
  txt(d,(112,1535),'Local Store · USD per 1 L package',24,TEAL,True)
  txt(d,(112,1590),'Lines connect recorded observations.',22,MUTED)
 elif index==7:
  card(715,'Save a full backup','Transfer products, shops, history and settings',height=150)
  card(895,'Restore a backup','Validate and preview before replacing your diary',height=150)
  card(1075,'Export CSV files','Products, shops and all price observations',height=150)
  card(1255,'Theme','Follow system · Light · Dark',height=150)
  card(1435,'Default currency','USD · No automatic currency conversion',height=150)
 # Navigation and explicit provenance visible on every draft.
 d.line((80,1680,1000,1680),fill='#DEE9E4',width=2)
 for x,label in [(139,'Home'),(355,'Products'),(594,'Shops'),(810,'Settings')]: txt(d,(x,1720),label,21,TEAL if index==0 else MUTED,True)
 txt(d,(76,1840),'ILLUSTRATIVE MOCKUP • SAMPLE DATA • NOT A LIVE CAPTURE',18,MUTED)
 im.save(OUT/'mockups'/f'{slug}.png')
# Overview sheet is for review, not a Play Console upload.
contact=Image.new('RGB',(1440,1480),'#E9F3EC'); dc=ImageDraw.Draw(contact)
for i,(slug,*_) in enumerate(slides):
 thumb=Image.open(OUT/'mockups'/f'{slug}.png').resize((324,576),Image.Resampling.LANCZOS)
 x=24+(i%4)*354; y=35+(i//4)*720; contact.paste(thumb,(x,y)); txt(dc,(x,y+590),slug,16,INK,True)
contact.save(OUT/'mockup-contact-sheet.jpg',quality=90)
print('Created icon, feature graphic, eight mockups, contact sheet and platform launcher sizes.')

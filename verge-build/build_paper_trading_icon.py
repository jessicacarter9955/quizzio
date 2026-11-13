from pathlib import Path
from math import hypot
import struct,zlib,json

BASE=Path('flutter_app')
STROKES=[
 (65,365,148,281),
 (148,281,222,327),
 (222,327,306,190),
 (306,190,388,244),
 (388,244,458,100),
 (389,103,458,100),
 (458,100,452,169)
]
def distance(px,py,a,b,c,d):
  dx=c-a;dy=d-b;t=max(0,min(1,((px-a)*dx+(py-b)*dy)/(dx*dx+dy*dy)))
  return hypot(px-(a+t*dx),py-(b+t*dy))
def raster(size):
  data=bytearray()
  for y in range(size):
    data.append(0)
    for x in range(size):
      # 2x2 sampling for smooth edges
      count=0
      for ox,oy in ((.25,.25),(.75,.25),(.25,.75),(.75,.75)):
        xx=(x+ox)*512/size;yy=(y+oy)*512/size
        if min(distance(xx,yy,*p) for p in STROKES)<14:count+=1
      blend=count/4
      data.extend((round(255*(1-blend)+41*blend),round(255*(1-blend)+98*blend),255,255))
  def chunk(k,body):
    return struct.pack('>I',len(body))+k+body+struct.pack('>I',zlib.crc32(k+body)&0xffffffff)
  return b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',size,size,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(bytes(data),8))+chunk(b'IEND',b'')
sizes={'mdpi':48,'hdpi':72,'xhdpi':96,'xxhdpi':144,'xxxhdpi':192}
for folder,px in sizes.items():
 p=BASE/'android'/'app'/'src'/'main'/'res'/('mipmap-'+folder)/'ic_launcher.png'
 p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(raster(px))
m=BASE/'android'/'app'/'src'/'main'/'AndroidManifest.xml'
manifest=m.read_text()
import re
new,n=re.subn(r'android:label="[^"]+"','android:label="Paper Trading"',manifest,count=1)
if n!=1:raise RuntimeError('Android app label not found')
m.write_text(new)
# iOS icon pngs when available (future iOS archive; not an IPA build).
iconDir=BASE/'ios'/'Runner'/'Assets.xcassets'/'AppIcon.appiconset'
contents=iconDir/'Contents.json'
if contents.exists():
  for item in json.loads(contents.read_text()).get('images',[]):
    filename=item.get('filename');size=item.get('size','')
    if not filename or 'x' not in size:continue
    logical=float(size.split('x')[0]);scale=float(item.get('scale','1x').removesuffix('x'))
    px=round(logical*scale)
    if px>0:(iconDir/filename).write_bytes(raster(px))
print('Paper Trading branded icons generated for Android and iOS')

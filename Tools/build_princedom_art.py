"""Reproducible vector-style emblems plus retained Una Court portrait artwork.

No downloaded art or AI regeneration required. DDS files have unique leaf names
to avoid Civ V's texture cache collisions. DXT5 for alpha, DXT1 for scenes.
"""
from pathlib import Path
import struct
from PIL import Image, ImageDraw, ImageOps
from build_ultimate_art import build_leader_icon

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'Princedom/Art'


def emblem(kind, alpha=False):
    im=Image.new('RGBA',(512,512),(0,0,0,0) if alpha else (34,17,58,255))
    d=ImageDraw.Draw(im)
    gold=(240,199,104,255)
    ink=(255,255,255,255) if alpha else gold
    if kind in (0,4):
        d.arc((90,70,422,402),28,208,fill=ink,width=24)
        d.arc((90,110,422,442),208,388,fill=ink,width=24)
        d.polygon([(404,120),(421,204),(340,180)],fill=ink)
        d.polygon([(108,392),(91,308),(172,332)],fill=ink)
        d.polygon([(155,215),(200,247),(256,175),(312,247),(357,215),(332,320),(180,320)],fill=ink)
    elif kind==3:
        d.polygon([(132,130),(240,148),(240,372),(132,354)],fill=ink)
        d.polygon([(272,148),(380,130),(380,354),(272,372)],fill=ink)
        d.line([(256,150),(256,376)],fill=ink,width=10)
        for y in (200,245,290):
            d.line([(156,y),(216,y+10)],fill=(78,39,107,255),width=8)
            d.line([(296,y+10),(356,y)],fill=(78,39,107,255),width=8)
    elif kind==5:
        d.ellipse((78,158,230,310),outline=ink,width=22)
        d.ellipse((282,158,434,310),outline=ink,width=22)
        d.line([(172,114),(354,114),(354,80)],fill=ink,width=18)
        d.polygon([(330,80),(354,46),(378,80)],fill=ink)
        d.line([(340,358),(158,358),(158,392)],fill=ink,width=18)
        d.polygon([(134,392),(158,426),(182,392)],fill=ink)
    elif kind==6:
        d.ellipse((90,160,422,352),outline=ink,width=20)
        d.ellipse((204,204,308,308),fill=ink)
        d.arc((120,80,392,432),200,340,fill=ink,width=16)
        d.polygon([(380,322),(410,370),(350,366)],fill=ink)
    else:
        d.ellipse((170,90,342,262),outline=ink,width=20)
        d.arc((110,210,402,468),180,360,fill=ink,width=26)
        d.line([(115,122),(398,396)],fill=ink,width=14)
    return im


def dds(image,path,fmt):
    """Write a complete mip chain, including non-power-of-two icon sizes."""
    levels=[]
    current=image
    while True:
        import io
        stream=io.BytesIO()
        current.save(stream,format='DDS',pixel_format=fmt)
        levels.append(stream.getvalue())
        if current.size==(1,1): break
        current=current.resize((max(1,current.width//2),max(1,current.height//2)),Image.Resampling.LANCZOS)
    header=bytearray(levels[0][:128])
    flags=struct.unpack_from('<I',header,8)[0]|0x20000
    struct.pack_into('<I',header,8,flags)
    struct.pack_into('<I',header,28,len(levels))
    struct.pack_into('<I',header,108,0x1000|0x8|0x400000)
    path.write_bytes(header+b''.join(data[128:] for data in levels))


def build():
    OUT.mkdir(parents=True,exist_ok=True)
    leader=Image.open(ROOT/'Art/Source/TrentLeader.png').convert('RGBA')
    unit=Image.open(ROOT/'Art/Source/TrentroulsUnit.png').convert('RGBA')
    portraits=[emblem(0),leader,unit,emblem(3),emblem(4),emblem(5),emblem(6)]
    rows=[]
    for size in (256,128,80,64,45,32):
        sheet=Image.new('RGBA',(size*4,size*2))
        for n,art in enumerate(portraits): sheet.paste(build_leader_icon(art,size),((n%4)*size,(n//4)*size))
        dds(sheet,OUT/f'PrinceAtlas{size}.dds','DXT5')
        dds(build_leader_icon(portraits[0],size),OUT/f'PrinceCiv{size}.dds','DXT5')
        rows += [f'<Row><Atlas>PRINCE_ATLAS</Atlas><IconSize>{size}</IconSize><Filename>Princedom/Art/PrinceAtlas{size}.dds</Filename><IconsPerRow>4</IconsPerRow><IconsPerColumn>2</IconsPerColumn></Row>',
                 f'<Row><Atlas>PRINCE_CIV_ATLAS</Atlas><IconSize>{size}</IconSize><Filename>Princedom/Art/PrinceCiv{size}.dds</Filename><IconsPerRow>1</IconsPerRow><IconsPerColumn>1</IconsPerColumn></Row>']
        if size==128:sheet.save(OUT/'PrincePreview.png')
    for size in (128,80,64,48,45,32,24,16):
        glyph=emblem(0,True).resize((size,size),Image.Resampling.LANCZOS)
        dds(glyph,OUT/f'PrinceAlpha{size}.dds','DXT5')
        rows.append(f'<Row><Atlas>PRINCE_ALPHA_ATLAS</Atlas><IconSize>{size}</IconSize><Filename>Princedom/Art/PrinceAlpha{size}.dds</Filename><IconsPerRow>1</IconsPerRow><IconsPerColumn>1</IconsPerColumn></Row>')
        if size in (32,24):
            dds(glyph,OUT/f'PrinceFlag{size}.dds','DXT5')
            rows.append(f'<Row><Atlas>PRINCE_FLAG_ATLAS</Atlas><IconSize>{size}</IconSize><Filename>Princedom/Art/PrinceFlag{size}.dds</Filename><IconsPerRow>1</IconsPerRow><IconsPerColumn>1</IconsPerColumn></Row>')
    dawn=Image.open(ROOT/'Art/Source/TrentDawnOfManPainted.png').convert('RGB')
    dds(ImageOps.fit(dawn,(1024,768)),OUT/'PrinceDawn.dds','DXT1')
    dds(ImageOps.fit(dawn,(1600,900)),OUT/'PrinceLeaderScene.dds','DXT1')
    map_art=Image.open(ROOT/'Art/Source/UnaCourtMapStyled.png').convert('RGB')
    dds(ImageOps.fit(map_art,(360,412)),OUT/'PrinceMap.dds','DXT1')
    (OUT/'PrinceLeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="Princedom/Art/PrinceLeaderScene.dds" />\n',encoding='utf-8')
    (OUT/'PrinceAtlases.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<GameData><IconTextureAtlases>\n'+'\n'.join(rows)+'\n</IconTextureAtlases></GameData>\n',encoding='utf-8')
    print('Built Princedom DDS atlases and scenes with mipmaps')


if __name__=='__main__':build()

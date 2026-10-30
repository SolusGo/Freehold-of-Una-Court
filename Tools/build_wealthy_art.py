"""Package Wealthy Trent art as mipmapped Civ V DDS; deterministic icon glyphs.

Scene generated using built-in imagegen with Art/Source/TrentLeader.png as
appearance reference. Prompt retained in Art/Source/WealthyTrent/PROMPT.md.
"""
from PIL import Image, ImageDraw, ImageOps
from build_princedom_art import dds
from build_ultimate_art import build_leader_icon
from validate_mod import ROOT

OUT = ROOT/'Art/WealthyTrent'


def emblem(palace=False, alpha=False):
    im = Image.new('RGBA',(512,512),(0,0,0,0) if alpha else (9,30,79,255))
    d = ImageDraw.Draw(im)
    gold = (255,255,255,255) if alpha else (242,197,91,255)
    if palace:
        d.polygon([(95,209),(256,100),(417,209)],fill=gold)
        d.rectangle((100,222,412,240),fill=gold)
        for x in (126,200,278,352): d.rectangle((x,250,x+30,355),fill=gold)
        d.rectangle((92,367,420,385),fill=gold)
        d.rectangle((76,397,436,416),fill=gold)
    else:
        for x,y in ((100,320),(204,352),(308,320)):
            for offset in (38,19,0):
                d.ellipse((x,y+offset,x+104,y+offset+46),fill=gold,outline=(9,30,79,255),width=5)
        d.polygon([(134,161),(190,190),(256,116),(322,190),(378,161),
                   (350,274),(162,274)],fill=gold)
        d.line((166,288,346,288),fill=gold,width=16)
    return im


def build():
    OUT.mkdir(parents=True,exist_ok=True)
    scene = Image.open(ROOT/'Art/Source/WealthyTrent/WealthyScene.png').convert('RGB')
    leader = scene.crop((80,0,810,730))
    rows=[]
    for name,atlas,art in [('Civ','WEALTHY_CIV_ATLAS',emblem()),
                           ('Leader','WEALTHY_LEADER_ATLAS',leader),
                           ('Palace','WEALTHY_PALACE_ATLAS',emblem(True))]:
        for size in (256,128,80,64,45,32):
            image=build_leader_icon(art,size)
            path=OUT/f'Wealthy{name}{size}.dds'
            dds(image,path,'DXT5')
            rows.append(f'<Row><Atlas>{atlas}</Atlas><IconSize>{size}</IconSize><Filename>{path.relative_to(ROOT).as_posix()}</Filename><IconsPerRow>1</IconsPerRow><IconsPerColumn>1</IconsPerColumn></Row>')
    for size in (128,80,64,48,45,32,24,16):
        image=emblem(alpha=True).resize((size,size),Image.Resampling.LANCZOS)
        path=OUT/f'WealthyAlpha{size}.dds'
        dds(image,path,'DXT5')
        rows.append(f'<Row><Atlas>WEALTHY_ALPHA_ATLAS</Atlas><IconSize>{size}</IconSize><Filename>{path.relative_to(ROOT).as_posix()}</Filename><IconsPerRow>1</IconsPerRow><IconsPerColumn>1</IconsPerColumn></Row>')
    dds(ImageOps.fit(scene,(1024,768)),OUT/'WealthyDawn.dds','DXT1')
    dds(ImageOps.fit(scene,(1600,900)),OUT/'WealthyLeaderScene.dds','DXT1')
    # Reuse the established court map, framed in the new national colors.
    map_art=ImageOps.fit(Image.open(ROOT/'Art/Source/UnaCourtMapStyled.png').convert('RGB'),(360,412))
    d=ImageDraw.Draw(map_art)
    d.rectangle((2,2,357,409),outline=(9,30,79),width=9)
    d.rectangle((12,12,347,399),outline=(242,197,91),width=3)
    dds(map_art,OUT/'WealthyMap.dds','DXT1')
    (OUT/'WealthyLeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="Art/WealthyTrent/WealthyLeaderScene.dds" />\n',encoding='utf-8')
    (OUT/'WealthyAtlases.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<GameData><IconTextureAtlases>\n'+'\n'.join(rows)+'\n</IconTextureAtlases></GameData>\n',encoding='utf-8')
    preview=Image.new('RGBA',(768,256))
    for i,path in enumerate(('WealthyCiv256.dds','WealthyLeader256.dds','WealthyPalace256.dds')):
        preview.paste(Image.open(OUT/path),(256*i,0))
    preview.save(OUT/'WealthyPreview.png')
    print('Built Wealthy icons, alpha atlases, Dawn, map and leader scene with mipmaps')


if __name__=='__main__':
    build()

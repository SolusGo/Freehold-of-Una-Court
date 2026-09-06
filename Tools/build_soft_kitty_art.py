"""Pack Soft Kitty art into Civ V sized, transparent gold-framed DDS atlases."""
from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
from build_ultimate_art import build_leader_icon

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'Art/Source/SoftKitty'
OUT = ROOT / 'Art/SoftKitty'
SIZES = (256, 128, 80, 64, 45, 32)


def build():
    OUT.mkdir(parents=True, exist_ok=True)
    dawn = Image.open(SOURCE / 'Dawn.png').convert('RGB')
    images = [Image.open(SOURCE / (name + '.png')).convert('RGB')
              for name in ('Emblem', 'Romantic', 'Comfort', 'Ability', 'Repercussions')]
    leader = dawn.crop((round(dawn.width*.17), round(dawn.height*.04),
                        round(dawn.width*.53), round(dawn.height*.52)))
    portraits = [images[0], leader, *images[1:]]
    atlas_rows = []
    for size in SIZES:
        sheet = Image.new('RGBA', (size*3, size*2), (0, 0, 0, 0))
        for index, portrait in enumerate(portraits):
            icon = build_leader_icon(portrait, size)
            sheet.paste(icon, ((index % 3)*size, (index // 3)*size))
            if index == 0:
                icon.save(OUT / f'Civ{size}.dds', pixel_format='DXT5')
        sheet.save(OUT / f'Atlas{size}.dds', pixel_format='DXT5')
        atlas_rows += [f'<Row><Atlas>SOFT_KITTY_ATLAS</Atlas><IconSize>{size}</IconSize><Filename>Art/SoftKitty/Atlas{size}.dds</Filename><IconsPerRow>3</IconsPerRow><IconsPerColumn>2</IconsPerColumn></Row>',
                       f'<Row><Atlas>SOFT_KITTY_CIV_ATLAS</Atlas><IconSize>{size}</IconSize><Filename>Art/SoftKitty/Civ{size}.dds</Filename><IconsPerRow>1</IconsPerRow><IconsPerColumn>1</IconsPerColumn></Row>']
        if size == 128:
            sheet.save(OUT / 'PortraitPreview.png')
    # Extract only the warm gold emblem, dropping the navy field. Alpha atlases
    # are tintable white glyphs; do not include the decorative portrait rim.
    master = ImageOps.fit(images[0], (512, 512), Image.Resampling.LANCZOS)
    alpha = Image.new('L', master.size)
    alpha.putdata([max(0, min(255, (r-b-25)*3)) for r, g, b in master.getdata()])
    box = alpha.point(lambda v: 255 if v > 40 else 0).getbbox()
    if box: alpha = alpha.crop(box)
    for size in (128, 80, 64, 45, 32, 24, 16):
        mask = ImageOps.contain(alpha, (round(size*.78), round(size*.78)), Image.Resampling.LANCZOS)
        glyph = Image.new('RGBA', (size,size), (255,255,255,0))
        full_mask = Image.new('L', (size,size), 0)
        full_mask.paste(mask, ((size-mask.width)//2, (size-mask.height)//2))
        glyph.putalpha(full_mask)
        glyph.save(OUT / f'Alpha{size}.dds', pixel_format='DXT5')
        atlas_rows.append(f'<Row><Atlas>SOFT_KITTY_ALPHA_ATLAS</Atlas><IconSize>{size}</IconSize><Filename>Art/SoftKitty/Alpha{size}.dds</Filename><IconsPerRow>1</IconsPerRow><IconsPerColumn>1</IconsPerColumn></Row>')
    ImageOps.fit(dawn, (1024,768), Image.Resampling.LANCZOS).save(OUT/'DawnOfMan.dds', pixel_format='DXT1')
    ImageOps.fit(dawn, (1600,900), Image.Resampling.LANCZOS).save(OUT/'LeaderScene.dds', pixel_format='DXT1')
    (OUT/'LeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="Art/SoftKitty/LeaderScene.dds" />\n', encoding='utf-8')
    (ROOT/'Art/SoftKitty_IconAtlases.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<GameData><IconTextureAtlases>\n'+ '\n'.join(atlas_rows)+'\n</IconTextureAtlases></GameData>\n', encoding='utf-8')
    print('Built six Soft Kitty portraits, civ and alpha atlases, Dawn of Man, and static leader scene')


if __name__ == '__main__':
    build()

"""Build Library Exile source art into Civ V DDS atlases."""
from pathlib import Path
from PIL import Image, ImageOps
from build_ultimate_art import build_leader_icon

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Art/Source"
OUT = ROOT / "Art/LibraryExile"
SIZES = (256, 128, 80, 64, 45, 32)


def build():
    OUT.mkdir(parents=True, exist_ok=True)
    dawn = Image.open(SOURCE / "LibraryExileDawn.png").convert("RGB")
    emblem = Image.open(SOURCE / "LibraryExileEmblem.png").convert("RGB")
    reader = Image.open(SOURCE / "LibraryExileReader.png").convert("RGB")
    library = Image.open(SOURCE / "LibraryExileSchoolLibrary.png").convert("RGB")
    leader = dawn.crop((round(dawn.width * .10), round(dawn.height * .08),
                        round(dawn.width * .55), round(dawn.height * .64)))
    portraits = (emblem, leader, reader, library)
    rows = []
    for size in SIZES:
        sheet = Image.new("RGBA", (size * 2, size * 2), (0, 0, 0, 0))
        for index, portrait in enumerate(portraits):
            icon = build_leader_icon(portrait, size)
            sheet.paste(icon, ((index % 2) * size, (index // 2) * size))
            if index == 0:
                icon.save(OUT / f"Civ{size}.dds", pixel_format="DXT5")
            elif index == 1:
                icon.save(OUT / f"Leader{size}.dds", pixel_format="DXT5")
            elif index == 2:
                icon.save(OUT / f"Reader{size}.dds", pixel_format="DXT5")
            elif index == 3:
                icon.save(OUT / f"SchoolLibrary{size}.dds", pixel_format="DXT5")
        sheet.save(OUT / f"Atlas{size}.dds", pixel_format="DXT5")
        rows += [f'<Row><Atlas>LIBRARY_EXILE_ATLAS</Atlas><IconSize>{size}</IconSize><Filename>Art/LibraryExile/Atlas{size}.dds</Filename><IconsPerRow>2</IconsPerRow><IconsPerColumn>2</IconsPerColumn></Row>',
                 f'<Row><Atlas>LIBRARY_EXILE_LEADER_ATLAS_V3</Atlas><IconSize>{size}</IconSize><Filename>Art/LibraryExile/Leader{size}.dds</Filename><IconsPerRow>1</IconsPerRow><IconsPerColumn>1</IconsPerColumn></Row>',
                 f'<Row><Atlas>LIBRARY_EXILE_READER_ATLAS_V3</Atlas><IconSize>{size}</IconSize><Filename>Art/LibraryExile/Reader{size}.dds</Filename><IconsPerRow>1</IconsPerRow><IconsPerColumn>1</IconsPerColumn></Row>',
                 f'<Row><Atlas>LIBRARY_EXILE_SCHOOL_ATLAS_V3</Atlas><IconSize>{size}</IconSize><Filename>Art/LibraryExile/SchoolLibrary{size}.dds</Filename><IconsPerRow>1</IconsPerRow><IconsPerColumn>1</IconsPerColumn></Row>',
                 f'<Row><Atlas>LIBRARY_EXILE_CIV_ATLAS_V2</Atlas><IconSize>{size}</IconSize><Filename>Art/LibraryExile/Civ{size}.dds</Filename><IconsPerRow>1</IconsPerRow><IconsPerColumn>1</IconsPerColumn></Row>']
        if size == 128:
            sheet.save(OUT / "PortraitPreview.png")
    master = ImageOps.fit(emblem, (512, 512), Image.Resampling.LANCZOS)
    alpha = Image.new("L", master.size)
    alpha.putdata([max(0, min(255, ((r + g) // 2 - b - 15) * 4)) for r, g, b in master.getdata()])
    box = alpha.point(lambda value: 255 if value > 36 else 0).getbbox()
    if box:
        alpha = alpha.crop(box)
    for size in (128, 80, 64, 48, 45, 32, 24, 16):
        mask = ImageOps.contain(alpha, (round(size * .76), round(size * .76)), Image.Resampling.LANCZOS)
        # Preserve a fully opaque core after DXT5 compression at 16/24 px.
        mask = mask.point(lambda value: 255 if value > 18 else 0)
        glyph = Image.new("RGBA", (size, size), (255, 255, 255, 0))
        full = Image.new("L", (size, size), 0)
        full.paste(mask, ((size - mask.width) // 2, (size - mask.height) // 2))
        glyph.putalpha(full)
        glyph.save(OUT / f"Alpha{size}.dds", pixel_format="DXT5")
        rows.append(f'<Row><Atlas>LIBRARY_EXILE_ALPHA_ATLAS</Atlas><IconSize>{size}</IconSize><Filename>Art/LibraryExile/Alpha{size}.dds</Filename><IconsPerRow>1</IconsPerRow><IconsPerColumn>1</IconsPerColumn></Row>')
    ImageOps.fit(dawn, (1024, 768), Image.Resampling.LANCZOS).save(OUT / "DawnOfMan.dds", pixel_format="DXT1")
    ImageOps.fit(dawn, (1600, 900), Image.Resampling.LANCZOS).save(OUT / "LeaderScene.dds", pixel_format="DXT1")
    ImageOps.fit(library, (360, 412), Image.Resampling.LANCZOS).save(OUT / "MapImage.dds", pixel_format="DXT1")
    (OUT / "LeaderScene.xml").write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="Art/LibraryExile/LeaderScene.dds" />\n', encoding="utf-8")
    (ROOT / "Art/LibraryExile_IconAtlases.xml").write_text('<?xml version="1.0" encoding="utf-8"?>\n<GameData><IconTextureAtlases>\n' + "\n".join(rows) + '\n</IconTextureAtlases></GameData>\n', encoding="utf-8")
    print("Built Library Exile portraits, civilization/alpha atlases, map, Dawn and leader scene")


if __name__ == "__main__":
    build()

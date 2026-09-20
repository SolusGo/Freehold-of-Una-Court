"""Build Phone Stealer source art into Civ V DDS atlases."""
from pathlib import Path

from PIL import Image, ImageDraw, ImageOps

from build_ultimate_art import build_leader_icon


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Art/Source/PhoneStealer"
OUT = ROOT / "Art/PhoneStealer"
SIZES = (256, 128, 80, 64, 45, 32)
ALPHA_SIZES = (128, 80, 64, 48, 45, 32, 24, 16)


def build_alpha(emblem: Image.Image) -> Image.Image:
    square = ImageOps.fit(emblem.convert("RGB"), (1024, 1024), Image.Resampling.LANCZOS)
    mask = Image.new("L", square.size, 0)
    pixels = mask.load()
    source = square.load()
    center = square.width / 2
    radius = square.width * 0.43
    for y in range(square.height):
        for x in range(square.width):
            if (x - center) ** 2 + (y - center) ** 2 > radius ** 2:
                continue
            red, green, blue = source[x, y]
            if (red > 55 and green < red * 0.72 and blue < red * 0.58) or max(red, green, blue) < 65:
                pixels[x, y] = 255
    box = mask.getbbox()
    return mask.crop(box) if box else mask


def build():
    OUT.mkdir(parents=True, exist_ok=True)
    emblem = Image.open(SOURCE / "Emblem.png").convert("RGB")
    leader = Image.open(SOURCE / "Leader.png").convert("RGB")
    ability = Image.open(SOURCE / "Ability.png").convert("RGBA")
    butler = Image.open(SOURCE / "Butler.png").convert("RGB")
    dawn = Image.open(SOURCE / "Dawn.png").convert("RGB")
    map_image = Image.open(SOURCE / "Map.png").convert("RGB")
    portraits = (emblem, leader, ability, butler)
    names = ("PhoneStealerCiv", "Leader", "Ability", "Butler")
    atlases = (
        "PHONE_STEALER_CIV_ATLAS",
        "PHONE_STEALER_LEADER_ATLAS",
        "PHONE_STEALER_ABILITY_ATLAS",
        "PHONE_STEALER_BUTLER_ATLAS",
    )
    rows = []
    for size in SIZES:
        sheet = Image.new("RGBA", (size * 2, size * 2), (0, 0, 0, 0))
        for index, portrait in enumerate(portraits):
            icon = build_leader_icon(portrait, size)
            sheet.paste(icon, ((index % 2) * size, (index // 2) * size))
            icon.save(OUT / f"{names[index]}{size}.dds", pixel_format="DXT5")
            rows.append(
                f"<Row><Atlas>{atlases[index]}</Atlas><IconSize>{size}</IconSize>"
                f"<Filename>Art/PhoneStealer/{names[index]}{size}.dds</Filename>"
                "<IconsPerRow>1</IconsPerRow><IconsPerColumn>1</IconsPerColumn></Row>"
            )
        sheet.save(OUT / f"Atlas{size}.dds", pixel_format="DXT5")
        rows.append(
            f"<Row><Atlas>PHONE_STEALER_ATLAS</Atlas><IconSize>{size}</IconSize>"
            f"<Filename>Art/PhoneStealer/Atlas{size}.dds</Filename>"
            "<IconsPerRow>2</IconsPerRow><IconsPerColumn>2</IconsPerColumn></Row>"
        )
        if size == 128:
            sheet.save(OUT / "PortraitPreview.png")

    alpha = build_alpha(emblem)
    for size in ALPHA_SIZES:
        glyph = ImageOps.contain(alpha, (round(size * 0.78), round(size * 0.78)), Image.Resampling.LANCZOS)
        glyph = glyph.point(lambda value: 255 if value > 24 else 0)
        full = Image.new("L", (size, size), 0)
        full.paste(glyph, ((size - glyph.width) // 2, (size - glyph.height) // 2))
        icon = Image.new("RGBA", (size, size), (255, 255, 255, 0))
        icon.putalpha(full)
        icon.save(OUT / f"Alpha{size}.dds", pixel_format="DXT5")
        rows.append(
            f"<Row><Atlas>PHONE_STEALER_ALPHA_ATLAS</Atlas><IconSize>{size}</IconSize>"
            f"<Filename>Art/PhoneStealer/Alpha{size}.dds</Filename>"
            "<IconsPerRow>1</IconsPerRow><IconsPerColumn>1</IconsPerColumn></Row>"
        )

    ImageOps.fit(dawn, (1024, 768), Image.Resampling.LANCZOS).save(
        OUT / "DawnOfMan.dds", pixel_format="DXT1"
    )
    ImageOps.fit(leader, (1600, 900), Image.Resampling.LANCZOS, centering=(0.5, 0.5)).save(
        OUT / "LeaderScene.dds", pixel_format="DXT1"
    )
    ImageOps.fit(map_image, (360, 412), Image.Resampling.LANCZOS).save(
        OUT / "MapImage.dds", pixel_format="DXT1"
    )
    (OUT / "LeaderScene.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<LeaderScene FallbackImage="Art/PhoneStealer/LeaderScene.dds" />\n',
        encoding="utf-8",
    )
    (ROOT / "Art/PhoneStealer_IconAtlases.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<GameData><IconTextureAtlases>\n'
        + "\n".join(rows)
        + "\n</IconTextureAtlases></GameData>\n",
        encoding="utf-8",
    )
    print("Built Phone Stealer portraits, alpha atlas, map, Dawn and leader scene")


if __name__ == "__main__":
    build()

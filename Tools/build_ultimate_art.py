"""Build Civ V DDS assets for Trentrouls, the Ultimate Possessor."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Art" / "Source"
ICON_SIZES = (256, 128, 80, 64, 45, 32)
ALPHA_SIZES = (128, 80, 64, 45, 32)


def save_dds(image: Image.Image, path: Path, pixel_format: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="DDS", pixel_format=pixel_format)


def build_leader_icon(source: Image.Image, size: int) -> Image.Image:
    """Frame a leader portrait like Civ V's circular, gold-rimmed icons."""
    scale = 4
    canvas_size = size * scale
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)

    def circle(inset: float, fill: tuple[int, int, int, int]) -> None:
        edge = round(canvas_size * inset)
        draw.ellipse((edge, edge, canvas_size - edge - 1, canvas_size - edge - 1), fill=fill)

    # Keep the visible footprint consistent with the existing Dominion portrait.
    # The alternating dark and gold rings remain readable down to the 32 px atlas.
    circle(0.060, (25, 16, 7, 230))
    circle(0.070, (116, 73, 15, 255))
    circle(0.082, (238, 188, 62, 255))
    circle(0.105, (63, 38, 8, 255))
    circle(0.119, (255, 221, 112, 255))
    circle(0.137, (80, 47, 10, 255))

    portrait_inset = round(canvas_size * 0.151)
    portrait_size = canvas_size - portrait_inset * 2
    portrait = ImageOps.fit(
        source,
        (portrait_size, portrait_size),
        method=Image.Resampling.LANCZOS,
        centering=(0.5, 0.43),
    ).convert("RGBA")
    mask = Image.new("L", (portrait_size, portrait_size), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, portrait_size - 1, portrait_size - 1), fill=255)
    canvas.paste(portrait, (portrait_inset, portrait_inset), mask)
    # Restore the circular edge after compositing the square portrait.
    final_mask = Image.new("L", (canvas_size, canvas_size), 0)
    ImageDraw.Draw(final_mask).ellipse(
        (
            round(canvas_size * 0.060),
            round(canvas_size * 0.060),
            canvas_size - round(canvas_size * 0.060) - 1,
            canvas_size - round(canvas_size * 0.060) - 1,
        ),
        fill=255,
    )
    canvas.putalpha(final_mask)
    return canvas.resize((size, size), Image.Resampling.LANCZOS)


def build_civilization_icon(source: Image.Image, size: int) -> Image.Image:
    """Remove the source's square field and match Civ V's circular icon footprint."""
    scale = 4
    canvas_size = size * scale
    diameter = round(canvas_size * 0.875)
    offset = (canvas_size - diameter) // 2

    # The generated source has a small black safety margin outside its medallion.
    # Crop that away before sizing so the gold rim remains legible at 32 and 45 px.
    trim = round(min(source.size) * 0.026)
    medallion = source.crop((trim, trim, source.width - trim, source.height - trim))
    medallion = ImageOps.fit(medallion, (diameter, diameter), Image.Resampling.LANCZOS).convert("RGBA")
    mask = Image.new("L", (diameter, diameter), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, diameter - 1, diameter - 1), fill=255)

    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    canvas.paste(medallion, (offset, offset), mask)
    return canvas.resize((size, size), Image.Resampling.LANCZOS)


def build() -> None:
    dawn = Image.open(SOURCE / "UltimatePossessorDawnOfMan.png").convert("RGB")
    emblem = Image.open(SOURCE / "UltimatePossessionEmblem.png").convert("RGB")
    mansion = Image.open(SOURCE / "Ultimate3UnaCourt.png").convert("RGB")

    dawn_frame = ImageOps.fit(dawn, (1024, 768), Image.Resampling.LANCZOS)
    save_dds(dawn_frame, ROOT / "Art" / "UltimateDawnOfMan" / "UltimateDawnOfMan.dds", "DXT1")

    # The crop keeps Trentrouls' face, glasses, beard, and purple-gold collar
    # legible even at the 32 px leader-list size.
    leader_master = dawn.crop((200, 48, 700, 548))
    for size in ICON_SIZES:
        icon = build_leader_icon(leader_master, size)
        save_dds(icon, ROOT / "Art" / "UltimateTrentLeader" / f"UltimateTrentIcon{size}.dds", "DXT5")

    emblem_master = ImageOps.fit(emblem, (1024, 1024), Image.Resampling.LANCZOS)
    for size in ICON_SIZES:
        icon = build_civilization_icon(emblem_master, size)
        save_dds(icon, ROOT / "Art" / "UltimateCivilization" / f"UltimateIcon{size}.dds", "DXT5")

    # Alpha atlases require a white symbol whose transparency carries the mask.
    # The luminance mapping extracts the gold emblem while dropping its purple
    # field and black corners.
    luminance = ImageOps.grayscale(emblem_master)
    mask = luminance.point(lambda value: max(0, min(255, (value - 48) * 3)))
    for size in ALPHA_SIZES:
        alpha = mask.resize((size, size), Image.Resampling.LANCZOS)
        rgba = Image.new("RGBA", (size, size), (255, 255, 255, 0))
        rgba.putalpha(alpha)
        save_dds(rgba, ROOT / "Art" / "UltimateCivilization" / f"UltimateAlpha{size}.dds", "DXT5")

    mansion_master = ImageOps.fit(mansion, (1024, 1024), Image.Resampling.LANCZOS)
    for size in ICON_SIZES:
        icon = mansion_master.resize((size, size), Image.Resampling.LANCZOS)
        save_dds(icon, ROOT / "Art" / "Ultimate3UnaCourt" / f"ThreeUnaCourtIcon{size}.dds", "DXT1")


if __name__ == "__main__":
    build()

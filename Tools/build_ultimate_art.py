"""Build Civ V DDS assets for Trentrouls, the Ultimate Possessor."""

from pathlib import Path

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Art" / "Source"
ICON_SIZES = (256, 128, 80, 64, 45, 32)
ALPHA_SIZES = (128, 80, 64, 45, 32)


def save_dds(image: Image.Image, path: Path, pixel_format: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="DDS", pixel_format=pixel_format)


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
        icon = ImageOps.fit(leader_master, (size, size), Image.Resampling.LANCZOS)
        save_dds(icon, ROOT / "Art" / "UltimateTrentLeader" / f"UltimateTrentIcon{size}.dds", "DXT1")

    emblem_master = ImageOps.fit(emblem, (1024, 1024), Image.Resampling.LANCZOS)
    for size in ICON_SIZES:
        icon = emblem_master.resize((size, size), Image.Resampling.LANCZOS)
        save_dds(icon, ROOT / "Art" / "UltimateCivilization" / f"UltimateIcon{size}.dds", "DXT1")

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

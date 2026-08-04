#!/usr/bin/env python3
# ─────────────────────────────────────────────────────────────────────────────
# Generador del ícono de aplicación — RootCause Mobile Inspector
#
# Fuente de verdad del ícono: ESTE script. No se editan los PNG a mano; se
# regeneran con `python scripts/make_app_icons.py` y se commitean.
#
# La marca es la misma que `landing/assets/favicon.svg`: anillos concéntricos
# (radar/diana) con núcleo — "llegar a la causa raíz". Se conservan las
# proporciones exactas del favicon (r 13 / 7 / 2 sobre lienzo 32) para que el
# ícono de la app y el de la web sean reconociblemente la misma identidad.
#
# Salidas:
#   android/app/src/main/res/mipmap-*/ic_launcher.png             (legacy)
#   android/app/src/main/res/mipmap-*/ic_launcher_round.png       (legacy round)
#   android/app/src/main/res/mipmap-*/ic_launcher_foreground.png  (adaptativo)
#   android/app/src/main/res/mipmap-*/ic_launcher_background.png  (adaptativo)
#   android/app/src/main/res/mipmap-*/ic_launcher_monochrome.png  (tema Android 13+)
#   ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png  (sin alfa)
#   landing/assets/icon-512.png                                   (web / og)
#
# Dependencia única: Pillow.
# ─────────────────────────────────────────────────────────────────────────────
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

# ── Paleta ───────────────────────────────────────────────────────────────────
# Fondo: el gris azulado de la landing (#0d1117) con un realce radial suave
# hacia el azul profundo del tema oscuro de la app (#0B1F2A).
BG_CENTER = (24, 36, 48)  # #182430
BG_EDGE = (9, 13, 18)  # #090D12
RING = (31, 111, 235)  # #1F6FEB — azul de marca (favicon + landing)
CORE = (79, 163, 209)  # #4FA3D1 — seedColor del tema de la app
GLOW = (79, 163, 209)

# ── Proporciones de la marca (heredadas del favicon: r13 / r7 / r2 en 32) ────
INNER_RATIO = 7 / 13  # radio del anillo interior / radio exterior
CORE_RATIO = 2 / 13  # radio del núcleo / radio exterior
OUTER_STROKE = 2 / 13  # grosor del anillo exterior / radio exterior
INNER_STROKE = 1.5 / 13  # grosor del anillo interior / radio exterior

SS = 4  # supermuestreo antes de reducir (antialiasing)

ROOT = Path(__file__).resolve().parent.parent
ANDROID_RES = ROOT / "android/app/src/main/res"
IOS_ICONS = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"

# Densidades Android: (carpeta, px del ícono legacy, px del lienzo adaptativo)
# El lienzo adaptativo es de 108 dp; el legacy de 48 dp.
DENSITIES = [
    ("mdpi", 48, 108),
    ("hdpi", 72, 162),
    ("xhdpi", 96, 216),
    ("xxhdpi", 144, 324),
    ("xxxhdpi", 192, 432),
]

# El ícono adaptativo solo muestra los 72 dp centrales de 108; la zona segura
# son los 66 dp centrales. La marca ocupa 56 dp → margen holgado en todas las
# máscaras (círculo, squircle, gota) sin quedar recortada.
ADAPTIVE_MARK = 56 / 108
# En el ícono legacy no hay máscara del sistema: la marca puede respirar más.
LEGACY_MARK = 0.60
# Radio de esquina del legacy — squircle aproximado al de Android/iOS.
LEGACY_RADIUS = 0.2237


def _gradient_bg(size: int) -> Image.Image:
    """Fondo con realce radial: claro al centro, profundo en los bordes."""
    mask = Image.radial_gradient("L").resize((size, size), Image.LANCZOS)
    center = Image.new("RGB", (size, size), BG_CENTER)
    edge = Image.new("RGB", (size, size), BG_EDGE)
    return Image.composite(edge, center, mask)


def _draw_mark(size: int, radius: float, ring: tuple, core: tuple, glow: bool) -> Image.Image:
    """Dibuja los anillos concéntricos centrados, sobre lienzo transparente."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cx = cy = size / 2

    if glow:
        halo = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        hd = ImageDraw.Draw(halo)
        gr = radius * 0.55
        hd.ellipse([cx - gr, cy - gr, cx + gr, cy + gr], fill=(*GLOW, 70))
        halo = halo.filter(ImageFilter.GaussianBlur(radius * 0.30))
        img.alpha_composite(halo)

    d = ImageDraw.Draw(img)

    def circle(r: float, width: float | None) -> None:
        box = [cx - r, cy - r, cx + r, cy + r]
        if width is None:
            d.ellipse(box, fill=(*core, 255))
        else:
            d.ellipse(box, outline=(*ring, 255), width=max(1, round(width)))

    # El trazo de PIL se dibuja hacia adentro del radio: se compensa para que
    # el diámetro nominal quede centrado sobre el trazo.
    outer_w = radius * OUTER_STROKE
    inner_w = radius * INNER_STROKE
    circle(radius - outer_w / 2, outer_w)
    circle(radius * INNER_RATIO - inner_w / 2, inner_w)
    circle(radius * CORE_RATIO, None)
    return img


def _compose(size: int, mark_ratio: float, *, shape: str, opaque: bool) -> Image.Image:
    """Ícono completo (fondo + marca). shape: 'rounded' | 'circle' | 'square'."""
    s = size * SS
    bg = _gradient_bg(s).convert("RGBA")

    if shape != "square":
        mask = Image.new("L", (s, s), 0)
        md = ImageDraw.Draw(mask)
        if shape == "circle":
            md.ellipse([0, 0, s - 1, s - 1], fill=255)
        else:
            md.rounded_rectangle([0, 0, s - 1, s - 1], radius=s * LEGACY_RADIUS, fill=255)
        bg.putalpha(mask)

    bg.alpha_composite(_draw_mark(s, s * mark_ratio / 2, RING, CORE, glow=True))
    out = bg.resize((size, size), Image.LANCZOS)
    if opaque:  # iOS rechaza canales alfa en los íconos de app
        flat = Image.new("RGB", (size, size), BG_EDGE)
        flat.paste(out, mask=out.split()[3])
        return flat
    return out


def _foreground(size: int) -> Image.Image:
    s = size * SS
    img = _draw_mark(s, s * ADAPTIVE_MARK / 2, RING, CORE, glow=True)
    return img.resize((size, size), Image.LANCZOS)


def _monochrome(size: int) -> Image.Image:
    """Capa monocroma (íconos temáticos de Android 13+): el sistema la tiñe."""
    s = size * SS
    white = (255, 255, 255)
    img = _draw_mark(s, s * ADAPTIVE_MARK / 2, white, white, glow=False)
    return img.resize((size, size), Image.LANCZOS)


def _save(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "PNG", optimize=True)
    print(f"  {path.relative_to(ROOT).as_posix()}  {img.size[0]}x{img.size[1]}")


def main() -> None:
    print("Android — íconos legacy y adaptativos:")
    for folder, legacy_px, adaptive_px in DENSITIES:
        out = ANDROID_RES / f"mipmap-{folder}"
        _save(_compose(legacy_px, LEGACY_MARK, shape="rounded", opaque=False), out / "ic_launcher.png")
        _save(_compose(legacy_px, LEGACY_MARK, shape="circle", opaque=False), out / "ic_launcher_round.png")
        _save(_gradient_bg(adaptive_px), out / "ic_launcher_background.png")
        _save(_foreground(adaptive_px), out / "ic_launcher_foreground.png")
        _save(_monochrome(adaptive_px), out / "ic_launcher_monochrome.png")

    print("iOS — AppIcon (sin canal alfa):")
    ios_sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for name, px in ios_sizes.items():
        _save(_compose(px, LEGACY_MARK, shape="square", opaque=True), IOS_ICONS / name)

    print("Web / landing:")
    _save(_compose(512, LEGACY_MARK, shape="rounded", opaque=False), ROOT / "landing/assets/icon-512.png")


if __name__ == "__main__":
    main()

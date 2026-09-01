#!/usr/bin/env python3
"""Генератор иконки приложения Chromify.

Рисует 1024x1024 PNG (тёмный скруглённый квадрат, многоцветное свечение,
белый символ питания) без внешних зависимостей — только stdlib.
Результат: app/assets/icon/app_icon.png; из него flutter_launcher_icons
делает иконки под Windows/Android/Web.
"""
import math
import os
import struct
import zlib

OUT = os.path.join(os.path.dirname(__file__), "..", "app", "assets", "icon", "app_icon.png")
SIZE = 1024
SS = 3  # суперсэмплинг для сглаживания


def lerp(a, b, t):
    return a + (b - a) * t


def mix(c1, c2, t):
    return tuple(lerp(c1[i], c2[i], t) for i in range(3))


def rounded_rect_alpha(x, y, w, r):
    """Мягкая маска скруглённого квадрата со стороной w и радиусом r."""
    cx = min(max(x, r), w - r)
    cy = min(max(y, r), w - r)
    d = math.hypot(x - cx, y - cy)
    return max(0.0, min(1.0, (r - d) + 0.5))


def glow(x, y, w, gx, gy, radius, strength):
    d = math.hypot(x - gx * w, y - gy * w) / (radius * w)
    return max(0.0, 1.0 - d) ** 2 * strength


def power_symbol_alpha(x, y, w):
    """Белый знак питания: разомкнутое сверху кольцо + вертикальная черта."""
    cx = cy = w / 2
    dx, dy = x - cx, y - cy
    d = math.hypot(dx, dy)
    R = w * 0.235
    th = w * 0.052
    a = 0.0
    # кольцо
    ring = max(0.0, min(1.0, (th - abs(d - R)) + 0.5))
    ang = math.degrees(math.atan2(dx, -dy))  # 0 = вверх
    gap = 42.0
    if abs(ang) < gap:
        # плавно гасим кольцо в разрыве
        ring *= max(0.0, (abs(ang) - (gap - 10.0)) / 10.0)
    a = max(a, ring)
    # вертикальная черта сверху к центру
    if -th <= dx <= th and -w * 0.30 <= dy <= w * 0.03:
        bar = max(0.0, min(1.0, (th - abs(dx)) + 0.5))
        a = max(a, bar)
    return a


def render(size):
    buf = bytearray(size * size * 4)
    big = size * SS
    # предрасчёт по субпикселям
    acc = [(0.0, 0.0, 0.0, 0.0)] * (size * size)
    for py in range(big):
        for px in range(big):
            x = (px + 0.5) / SS
            y = (py + 0.5) / SS
            mask = rounded_rect_alpha(x, y, size, size * 0.225)
            if mask <= 0:
                col = (0.0, 0.0, 0.0)
                out_a = 0.0
            else:
                t = y / size
                col = mix((0x14, 0x12, 0x2A), (0x0A, 0x0A, 0x18), t)
                for gx, gy, rad, st, c in (
                    (0.30, 0.30, 0.55, 0.9, (0x6C, 0x7B, 0xFF)),
                    (0.78, 0.40, 0.5, 0.8, (0x23, 0xE0, 0xD4)),
                    (0.60, 0.85, 0.55, 0.7, (0xE0, 0x39, 0xC6)),
                ):
                    g = glow(x, y, size, gx, gy, rad, st)
                    col = mix(col, c, min(0.85, g))
                ps = power_symbol_alpha(x, y, size)
                if ps > 0:
                    col = mix(col, (0xF6, 0xF7, 0xFF), ps)
                out_a = mask
            i = (py // SS) * size + (px // SS)
            r0, g0, b0, a0 = acc[i]
            acc[i] = (r0 + col[0], g0 + col[1], b0 + col[2], a0 + out_a)

    n = SS * SS
    for i in range(size * size):
        r0, g0, b0, a0 = acc[i]
        j = i * 4
        buf[j] = int(max(0, min(255, r0 / n)))
        buf[j + 1] = int(max(0, min(255, g0 / n)))
        buf[j + 2] = int(max(0, min(255, b0 / n)))
        buf[j + 3] = int(max(0, min(255, a0 / n * 255)))
    return bytes(buf)


def write_png(path, size, rgba):
    def chunk(tag, data):
        return (
            struct.pack(">I", len(data))
            + tag
            + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    raw = bytearray()
    for y in range(size):
        raw.append(0)
        raw.extend(rgba[y * size * 4 : (y + 1) * size * 4])
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(png)


if __name__ == "__main__":
    print(f"rendering {SIZE}x{SIZE} (ss={SS})…")
    write_png(os.path.abspath(OUT), SIZE, render(SIZE))
    print("written:", os.path.abspath(OUT))

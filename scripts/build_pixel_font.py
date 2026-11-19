"""Build the project's original pixel font and an inspection sample."""
from pathlib import Path
import struct
import zlib

ROWS = {
    ' ': '00 00 00 00 00 00 00', '!': '04 04 04 04 04 00 04',
    '"': '0a 0a 0a 00 00 00 00', '#': '0a 1f 0a 0a 1f 0a 00',
    '$': '04 0f 14 0e 05 1e 04', '%': '19 19 02 04 08 13 13',
    '&': '0c 12 14 08 15 12 0d', "'": '04 04 08 00 00 00 00',
    '(': '02 04 08 08 08 04 02', ')': '08 04 02 02 02 04 08',
    '*': '00 15 0e 1f 0e 15 00', '+': '00 04 04 1f 04 04 00',
    ',': '00 00 00 00 00 04 08', '-': '00 00 00 1f 00 00 00',
    '.': '00 00 00 00 00 00 04', '/': '01 02 02 04 08 08 10',
    '0': '0e 11 13 15 19 11 0e', '1': '04 0c 04 04 04 04 0e',
    '2': '0e 11 01 02 04 08 1f', '3': '1e 01 01 0e 01 01 1e',
    '4': '02 06 0a 12 1f 02 02', '5': '1f 10 10 1e 01 01 1e',
    '6': '06 08 10 1e 11 11 0e', '7': '1f 01 02 04 08 08 08',
    '8': '0e 11 11 0e 11 11 0e', '9': '0e 11 11 0f 01 02 0c',
    ':': '00 04 00 00 04 00 00', ';': '00 04 00 00 04 04 08',
    '<': '02 04 08 10 08 04 02', '=': '00 00 1f 00 1f 00 00',
    '>': '08 04 02 01 02 04 08', '?': '0e 11 01 02 04 00 04',
    '@': '0e 11 17 15 17 10 0e',
    'A': '0e 11 11 1f 11 11 11', 'B': '1e 11 11 1e 11 11 1e',
    'C': '0f 10 10 10 10 10 0f', 'D': '1e 11 11 11 11 11 1e',
    'E': '1f 10 10 1e 10 10 1f', 'F': '1f 10 10 1e 10 10 10',
    'G': '0f 10 10 17 11 11 0f', 'H': '11 11 11 1f 11 11 11',
    'I': '0e 04 04 04 04 04 0e', 'J': '07 02 02 02 02 12 0c',
    'K': '11 12 14 18 14 12 11', 'L': '10 10 10 10 10 10 1f',
    'M': '11 1b 15 15 11 11 11', 'N': '11 19 19 15 13 13 11',
    'O': '0e 11 11 11 11 11 0e', 'P': '1e 11 11 1e 10 10 10',
    'Q': '0e 11 11 11 15 12 0d', 'R': '1e 11 11 1e 14 12 11',
    'S': '0f 10 10 0e 01 01 1e', 'T': '1f 04 04 04 04 04 04',
    'U': '11 11 11 11 11 11 0e', 'V': '11 11 11 11 11 0a 04',
    'W': '11 11 11 15 15 1b 11', 'X': '11 11 0a 04 0a 11 11',
    'Y': '11 11 0a 04 04 04 04', 'Z': '1f 01 02 04 08 10 1f',
    '[': '0e 08 08 08 08 08 0e', '\\': '10 08 08 04 02 02 01',
    ']': '0e 02 02 02 02 02 0e', '^': '04 0a 11 00 00 00 00',
    '_': '00 00 00 00 00 00 1f', '`': '08 04 02 00 00 00 00',
    'a': '00 00 0e 01 0f 11 0f', 'b': '10 10 1e 11 11 11 1e',
    'c': '00 00 0f 10 10 10 0f', 'd': '01 01 0f 11 11 11 0f',
    'e': '00 00 0e 11 1f 10 0f', 'f': '06 08 08 1e 08 08 08',
    'g': '00 0f 11 11 0f 01 0e', 'h': '10 10 1e 11 11 11 11',
    'i': '04 00 0c 04 04 04 0e', 'j': '02 00 06 02 02 12 0c',
    'k': '10 10 12 14 18 14 12', 'l': '0c 04 04 04 04 04 0e',
    'm': '00 00 1a 15 15 15 15', 'n': '00 00 1e 11 11 11 11',
    'o': '00 00 0e 11 11 11 0e', 'p': '00 1e 11 11 1e 10 10',
    'q': '00 0f 11 11 0f 01 01', 'r': '00 00 16 19 10 10 10',
    's': '00 00 0f 10 0e 01 1e', 't': '08 08 1e 08 08 09 06',
    'u': '00 00 11 11 11 13 0d', 'v': '00 00 11 11 11 0a 04',
    'w': '00 00 11 11 15 15 0a', 'x': '00 00 11 0a 04 0a 11',
    'y': '00 11 11 11 0f 01 0e', 'z': '00 00 1f 02 04 08 1f',
    '{': '03 04 04 18 04 04 03', '|': '04 04 04 04 04 04 04',
    '}': '18 04 04 03 04 04 18', '~': '00 00 09 16 00 00 00',
}


def png(path, width, height, pixels):
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    raw = b''.join(b'\0' + bytes(pixels[y * width * 4:(y + 1) * width * 4]) for y in range(height))
    path.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))
                     + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b''))


def main():
    assert set(ROWS) == {chr(code) for code in range(32, 127)}
    ROWS['\u2026'] = '00 00 00 00 00 00 15'
    output = Path(__file__).resolve().parent.parent / 'assets/ui/font'
    output.mkdir(parents=True, exist_ok=True)
    pixels = bytearray(128 * 64 * 4)
    descriptor = ['info face="Dungeon Pixel" size=8 bold=0 italic=0 unicode=1 smooth=0 aa=1',
                  'common lineHeight=10 base=8 scaleW=128 scaleH=64 pages=1 packed=0',
                  'page id=0 file="dungeon-pixel.png"', f'chars count={len(ROWS)}']
    for index, (char, encoded) in enumerate(ROWS.items()):
        rows = [int(value, 16) for value in encoded.split()]
        assert len(rows) == 7 and all(0 <= value < 32 for value in rows)
        columns = [x for x in range(5) if any(row & (16 >> x) for row in rows)]
        left, width = (min(columns), max(columns) - min(columns) + 1) if columns else (0, 3)
        origin_x, origin_y = (index % 16) * 8, (index // 16) * 10
        for y, row in enumerate(rows):
            for x in columns:
                if row & (16 >> x):
                    offset = ((origin_y + y) * 128 + origin_x + x - left) * 4
                    pixels[offset:offset + 4] = b'\xff\xff\xff\xff'
        descriptor.append(f'char id={ord(char)} x={origin_x} y={origin_y} width={width} height=7 xoffset=0 yoffset=1 xadvance={width + 1} page=0 chnl=15')
    png(output / 'dungeon-pixel.png', 128, 64, pixels)
    (output / 'dungeon-pixel.fnt').write_text('\n'.join(descriptor) + '\n')
    sample_dir = output.parents[2] / '.godot/pixel-preview'
    sample_dir.mkdir(parents=True, exist_ok=True)
    canvas = bytearray(bytes((17, 26, 34, 255)) * (720 * 220))
    lines = [('Minimized Dungeon', 3), ('Hero / Pets / Dungeon / Settings', 2),
             ('0123456789  +0.15/s  55%  1%  1000000000000 gold', 2),
             ('Common  Uncommon  Rare  Epic  Legendary', 2),
             ('Rare Swift Rabbit! Duplicate: +1 pet level.', 2),
             ('Save failed. Previous progress is retained.', 2)]
    top = 16
    for text, scale in lines:
        pen = 16
        for char in text:
            rows = [int(value, 16) for value in ROWS[char].split()]
            columns = [x for x in range(5) if any(row & (16 >> x) for row in rows)]
            left, width = (min(columns), max(columns) - min(columns) + 1) if columns else (0, 3)
            for y, row in enumerate(rows):
                for x in columns:
                    if row & (16 >> x):
                        for dy in range(scale):
                            for dx in range(scale):
                                pixel_x = pen + (x - left) * scale + dx
                                pixel_y = top + y * scale + dy
                                assert pixel_x < 720 and pixel_y < 220
                                offset = (pixel_y * 720 + pixel_x) * 4
                                canvas[offset:offset + 4] = bytes((240, 230, 206, 255))
            pen += (width + 1) * scale
        top += 34 if scale == 3 else 30
    png(sample_dir / 'font-sample.png', 720, 220, canvas)
    print('Original pixel font built: 95 printable ASCII glyphs plus ellipsis; grid checks passed.')


if __name__ == '__main__':
    main()

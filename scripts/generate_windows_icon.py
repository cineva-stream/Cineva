"""
Generates 100% compliant Windows ICO file with uncompressed 32-bit DIB bitmaps
for standard sizes (16, 20, 24, 30, 32, 36, 40, 48, 64, 128) and PNG for 256x256.
Ensures Windows Explorer in Details/List view and Inno Setup display the icon properly.
"""
import struct
import io
import os
from PIL import Image

def generate_ico(png_path, out_paths):
    if not os.path.exists(png_path):
        raise FileNotFoundError(f"Source image not found: {png_path}")

    src_img = Image.open(png_path).convert('RGBA')
    bmp_sizes = [16, 20, 24, 30, 32, 36, 40, 48, 64, 128]
    payloads = []

    for s in bmp_sizes:
        resized = src_img.resize((s, s), Image.Resampling.LANCZOS)
        pix = resized.load()
        xor_data = bytearray()
        row_bytes = (s + 31) // 32 * 4
        and_mask = bytearray(row_bytes * s)
        
        # Windows DIB rows are stored bottom-up
        for y in range(s - 1, -1, -1):
            for x in range(s):
                r, g, b, a = pix[x, y]
                xor_data.extend([b, g, r, a])
                if a < 128:
                    byte_idx = (s - 1 - y) * row_bytes + (x // 8)
                    bit_idx = 7 - (x % 8)
                    and_mask[byte_idx] |= (1 << bit_idx)
                    
        bih = struct.pack('<IIIHHIIIIII', 40, s, s * 2, 1, 32, 0, len(xor_data), 0, 0, 0, 0)
        dib_payload = bih + bytes(xor_data) + bytes(and_mask)
        payloads.append((s, dib_payload))

    # 256x256 as PNG
    s256 = src_img.resize((256, 256), Image.Resampling.LANCZOS)
    buf = io.BytesIO()
    s256.save(buf, format='PNG')
    payloads.append((256, buf.getvalue()))

    # Pack ICO
    count = len(payloads)
    header = struct.pack('<HHH', 0, 1, count)
    offset = 6 + count * 16

    entry_data = bytearray()
    for s, payload in payloads:
        w = 0 if s == 256 else s
        h = 0 if s == 256 else s
        size = len(payload)
        entry_data.extend(struct.pack('<BBBBHHII', w, h, 0, 0, 1, 32, size, offset))
        offset += size

    ico_bytes = header + bytes(entry_data) + b''.join(p[1] for p in payloads)

    for out_path in out_paths:
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        with open(out_path, 'wb') as f:
            f.write(ico_bytes)
        print(f"Generated {out_path} ({len(ico_bytes)} bytes, {count} frames)")

if __name__ == '__main__':
    generate_ico(
        'assets/images/cineva_icon.png',
        [
            'windows/runner/resources/app_icon.ico',
            'windows/installer/app_icon.ico',
        ]
    )


from pathlib import Path

root = Path(__file__).resolve().parents[1]
st_path = Path(__file__).resolve().parent / "STCharacters.txt"
s2t = {}
for line in st_path.read_text(encoding="utf-8").splitlines():
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    parts = line.split()
    if len(parts) < 2:
        continue
    simp = parts[0]
    trad = parts[1]  # first traditional is OpenCC default
    if len(simp) == 1 and len(trad) >= 1:
        # character map: single char keys; multi-char phrases skipped here
        s2t[simp] = trad[0] if len(trad) > 1 and len(parts) == 2 else trad
        # OpenCC format: "丝 絲" or sometimes multi
        if len(simp) == 1 and len(trad) == 1:
            s2t[simp] = trad
        elif len(simp) == 1:
            s2t[simp] = parts[1][0] if parts[1] else simp

# Re-parse cleanly
s2t = {}
for line in st_path.read_text(encoding="utf-8").splitlines():
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    parts = line.split()
    if len(parts) < 2:
        continue
    simp, trad = parts[0], parts[1]
    if len(simp) == 1 and len(trad) == 1:
        s2t[simp] = trad

out = root / "lib/core/utils/zh_s2t_data.dart"
lines = [
    "// Generated from OpenCC STCharacters\n",
    "const Map<String, String> kZhSimplifiedToTraditional = {\n",
]
for s, t in sorted(s2t.items(), key=lambda x: x[0]):
    lines.append(f"  '{s}': '{t}',\n")
lines.append("};\n")
out.write_text("".join(lines), encoding="utf-8")
print(f"wrote {len(s2t)} entries")
# sanity
assert s2t.get("动") == "動"
assert s2t.get("画") == "畫"
assert s2t.get("巨") == "巨" or "巨" not in s2t  # identity or absent
print("巨 ->", s2t.get("巨", "(absent)"))
print("人 ->", s2t.get("人", "(absent)"))

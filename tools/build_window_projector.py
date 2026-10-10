"""Generate the original window-light gobo used by SpotLight3D (Pillow)."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

target = Path(__file__).resolve().parents[1] / "game/assets/textures/study_window.png"
image = Image.new("RGB", (512, 512), "black")
draw = ImageDraw.Draw(image)
draw.rectangle((65, 105, 447, 407), fill="white")
draw.rectangle((186, 105, 199, 407), fill="black")
draw.rectangle((313, 105, 326, 407), fill="black")
draw.rectangle((65, 248, 447, 262), fill="black")
image.filter(ImageFilter.GaussianBlur(5.5)).save(target)
print(target)

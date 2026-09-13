import base64
import math
import struct

sample_rate = 44100
duration = 0.015 # 15 ms very short, modern UI tick
num_samples = int(sample_rate * duration)

data = bytearray()
phase = 0.0

for i in range(num_samples):
    progress = float(i) / num_samples
    
    # Exponential pitch sweep for a snappy click
    freq = 2500.0 * math.pow(400.0 / 2500.0, progress)
    
    phase += 2.0 * math.pi * freq / sample_rate
    
    # Fast fade out
    env = 1.0 - progress
    
    val = math.sin(phase) * 0.4 * env
    
    int_val = int(val * 32767.0)
    data.extend(struct.pack('<h', int_val))

base64_str = base64.b64encode(data).decode('ascii')

content = f"""[gd_resource type="AudioStreamWAV" format=4]

[resource]
format = 1
mix_rate = 44100
data = PackedByteArray("{base64_str}")
"""

with open("D:/Development/NightShift/assets/audio/ui/ui_click.tres", "w") as f:
    f.write(content)
print("Updated ui_click.tres")

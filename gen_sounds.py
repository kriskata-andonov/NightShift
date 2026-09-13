import wave
import math
import struct
import os

def generate_wave(filename, freq_start, freq_end, duration_ms, volume=0.5, wave_type='sine'):
    sample_rate = 44100
    num_samples = int(sample_rate * (duration_ms / 1000.0))
    
    # Ensure dir exists
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = float(i) / sample_rate
            progress = float(i) / num_samples
            
            # frequency sweep
            freq = freq_start + (freq_end - freq_start) * progress
            
            # Envelope (fade in / out quickly)
            env = 1.0
            if progress < 0.1:
                env = progress / 0.1
            elif progress > 0.9:
                env = (1.0 - progress) / 0.1
            
            if wave_type == 'sine':
                value = math.sin(2.0 * math.pi * freq * t)
            elif wave_type == 'square':
                value = 1.0 if math.sin(2.0 * math.pi * freq * t) > 0 else -1.0
            
            # Attenuate by volume and envelope
            value = value * volume * env
            
            # Scale to 16-bit int
            packed_value = struct.pack('h', int(value * 32767.0))
            wav_file.writeframes(packed_value)

if __name__ == "__main__":
    # Hover: Quick, low-ish frequency sine wave blip
    generate_wave("assets/audio/ui/ui_hover.wav", freq_start=300, freq_end=400, duration_ms=40, volume=0.3, wave_type='sine')
    
    # Click: Sharp, higher frequency square wave
    generate_wave("assets/audio/ui/ui_click.wav", freq_start=600, freq_end=500, duration_ms=60, volume=0.4, wave_type='sine')
    
    print("Generated UI sounds!")

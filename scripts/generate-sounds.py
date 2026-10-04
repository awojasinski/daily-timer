#!/usr/bin/env python3
"""Synthesize original bell and toaster-spring cues without sampled audio."""
import math
from pathlib import Path
import random
import struct
import wave

sample_rate = 44100
output_directory = Path(__file__).resolve().parent.parent / 'Sources/DailyTimer/Sounds'
random_source = random.Random(7)

for name, duration in [('ReceptionBell', 3.0), ('ToasterPop', 0.95)]:
    samples = []
    for index in range(round(sample_rate * duration)):
        time = index / sample_rate
        if name == 'ReceptionBell':
            partials = [(1760, 1.0, 1.25), (2781, 0.38, 0.8), (3916, 0.2, 0.5), (5280, 0.1, 0.25)]
            value = sum(gain * math.exp(-time / decay) * math.sin(2 * math.pi * frequency * time)
                        for frequency, gain, decay in partials)
            value *= 1 - math.exp(-time * 1600)
        else:
            noise = random_source.uniform(-1, 1)
            latch = noise * math.exp(-time * 210) * 0.65
            spring_time = max(0, time - 0.018)
            # Integrated frequency glide gives a damped, metallic spring twang.
            phase = 2 * math.pi * (155 * spring_time + 85 * 0.085 * (1 - math.exp(-spring_time / 0.085)))
            spring = sum(gain * math.sin(phase * ratio) * math.exp(-spring_time / decay)
                         for ratio, gain, decay in [(1, 0.65, 0.17), (2.73, 0.35, 0.14), (5.19, 0.2, 0.09), (8.41, 0.12, 0.055)])
            spring *= 1 - math.exp(-spring_time * 950)
            catch_time = max(0, time - 0.105)
            catch = (noise * 0.35 + math.sin(2 * math.pi * 720 * catch_time) * 0.28) * math.exp(-catch_time * 85) if time >= 0.105 else 0
            value = latch + spring + catch
        value *= min(1, (duration - time) / 0.1)
        if name == 'ReceptionBell':
            value *= 0.21
        samples.append(struct.pack('<h', round(max(-1, min(1, value * 0.48)) * 32767)))
    with wave.open(str(output_directory / f'{name}.wav'), 'wb') as output:
        output.setparams((1, 2, sample_rate, 0, 'NONE', 'not compressed'))
        output.writeframes(b''.join(samples))

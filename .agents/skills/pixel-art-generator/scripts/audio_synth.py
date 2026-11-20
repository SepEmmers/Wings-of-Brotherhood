"""
Physical-Modeling & Multi-Track Procedural Audio Synthesizer
for Temeraire: Wings of the Brotherhood (44.1 kHz, 16-bit PCM WAV).

Uses NumPy to generate:
- 5 seamless looping adaptive medieval music + ambient tracks
- Surface-aware multi-variant footsteps (cobble, wood, grass)
- Expressive character-specific dialogue voice syllables
- Tactile knotcraft, rope, harbor bell, splash, door, parchment & dragon SFX
"""

import os
import struct
import wave
import numpy as np

SR = 44100


def save_wav(audio_dir: str, filename: str, samples: np.ndarray, sr: int = SR):
    path = os.path.join(audio_dir, filename)
    clipped = np.clip(samples, -0.97, 0.97)
    pcm = (clipped * 32767.0).astype("<i2")
    with wave.open(path, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sr)
        wf.writeframes(pcm.tobytes())


def _fft_bandpass(noise: np.ndarray, low_hz: float, high_hz: float, sr: int = SR) -> np.ndarray:
    n = len(noise)
    spec = np.fft.rfft(noise)
    freqs = np.fft.rfftfreq(n, 1.0 / sr)
    mask = np.ones_like(freqs)
    if low_hz > 0.0:
        mask *= np.clip((freqs - low_hz * 0.6) / max(1.0, low_hz * 0.4), 0.0, 1.0)
    if high_hz < sr * 0.5:
        mask *= np.clip((high_hz * 1.4 - freqs) / max(1.0, high_hz * 0.4), 0.0, 1.0)
    return np.fft.irfft(spec * mask, n=n)


def karplus_strong(freq: float, dur: float, brightness: float = 0.65, damp: float = 0.996, sr: int = SR) -> np.ndarray:
    """Physical-modeled plucked lute / harp string."""
    n = int(sr * dur)
    delay = max(2, int(round(sr / freq)))
    rng = np.random.default_rng(int(freq * 100) + n)
    # Softened pluck excitation
    exc = rng.uniform(-1.0, 1.0, delay)
    for _ in range(int((1.0 - brightness) * 5)):
        exc = 0.5 * (exc + np.roll(exc, 1))
    out = np.zeros(n, dtype=np.float64)
    buf = exc.copy()
    idx = 0
    prev = 0.0
    for i in range(n):
        val = buf[idx]
        out[i] = val
        nxt = buf[(idx + 1) % delay]
        # Low-pass loop filter simulating wooden lute body damping
        filtered = damp * (0.52 * val + 0.48 * nxt)
        buf[idx] = 0.85 * filtered + 0.15 * prev
        prev = buf[idx]
        idx = (idx + 1) % delay
    # Smooth micro-attack & release tail
    att = min(n, int(sr * 0.004))
    rel = min(n, int(sr * 0.05))
    if att > 0:
        out[:att] *= np.linspace(0.0, 1.0, att)
    if rel > 0:
        out[-rel:] *= np.linspace(1.0, 0.0, rel)
    return out


def wooden_flute(freq: float, dur: float, vib_hz: float = 4.6, sr: int = SR) -> np.ndarray:
    """Warm medieval recorder / wooden flute with soft breath onset."""
    n = int(sr * dur)
    t = np.arange(n) / sr
    vib = 1.0 + 0.0055 * np.sin(2.0 * np.pi * vib_hz * t) * np.minimum(1.0, t / 0.25)
    phase = 2.0 * np.pi * np.cumsum(freq * vib) / sr
    tone = (
        0.74 * np.sin(phase)
        + 0.18 * np.sin(2.0 * phase + 0.3)
        + 0.06 * np.sin(3.0 * phase)
    )
    rng = np.random.default_rng(int(freq * 13) + 7)
    breath = _fft_bandpass(rng.normal(0.0, 1.0, n), freq * 0.8, freq * 3.0, sr)
    breath *= np.exp(-t * 10.0) * 0.08 + 0.02
    env = np.minimum(1.0, t / 0.07) * np.minimum(1.0, (dur - t) / 0.10)
    return (tone * 0.32 + breath) * np.maximum(0.0, env)


def bowed_viol(freq: float, dur: float, sr: int = SR) -> np.ndarray:
    """Warm medieval bowed viol/cello pad for atmosphere and tension."""
    n = int(sr * dur)
    t = np.arange(n) / sr
    vib = 1.0 + 0.003 * np.sin(2.0 * np.pi * 3.8 * t)
    phase = 2.0 * np.pi * np.cumsum(freq * vib) / sr
    # Warm saw-like mellow string harmonics
    sig = np.zeros(n, dtype=np.float64)
    for k, amp in ((1, 0.55), (2, 0.26), (3, 0.14), (4, 0.07), (5, 0.03)):
        sig += amp * np.sin(k * phase + k * 0.4)
    env = np.minimum(1.0, t / 0.45) * np.minimum(1.0, (dur - t) / 0.55)
    return sig * np.maximum(0.0, env) * 0.22


def bronze_bell(freq: float, dur: float, sr: int = SR) -> np.ndarray:
    """Inharmonic medieval bronze bell partials."""
    n = int(sr * dur)
    t = np.arange(n) / sr
    partials = [
        (0.50, 0.28, 1.6),
        (1.00, 0.50, 2.0),
        (1.20, 0.32, 2.5),
        (1.50, 0.22, 3.0),
        (2.00, 0.18, 3.8),
        (2.76, 0.10, 5.2),
    ]
    sig = np.zeros(n, dtype=np.float64)
    for ratio, amp, decay in partials:
        sig += amp * np.sin(2.0 * np.pi * freq * ratio * t) * np.exp(-t * decay)
    att = min(n, int(sr * 0.003))
    if att > 0:
        sig[:att] *= np.linspace(0.0, 1.0, att)
    return sig * 0.48


def frame_drum(pitch_hz: float = 88.0, dur: float = 0.24, sr: int = SR) -> np.ndarray:
    """Medieval bodhran / war-drum strike with rapid tension-skin pitch drop."""
    n = int(sr * dur)
    t = np.arange(n) / sr
    rng = np.random.default_rng(int(pitch_hz * 19) + n)
    freq_env = pitch_hz * (1.0 + 0.95 * np.exp(-t * 28.0))
    ph = 2.0 * np.pi * np.cumsum(freq_env) / sr
    body = np.sin(ph) * np.exp(-t * 11.5)
    skin = _fft_bandpass(rng.normal(0.0, 1.0, n), 120.0, 640.0, sr) * np.exp(-t * 32.0) * 0.42
    att = min(n, int(sr * 0.003))
    if att > 0:
        body[:att] *= np.linspace(0.0, 1.0, att)
    return (body * 0.72 + skin)


def snare_tap(dur: float = 0.14, rim: bool = False, sr: int = SR) -> np.ndarray:
    """Crisp medieval side-drum snap or hushed wooden block tick."""
    n = int(sr * dur)
    t = np.arange(n) / sr
    rng = np.random.default_rng(int(dur * 1000) + (9 if rim else 3))
    if rim:
        hit = np.sin(2.0 * np.pi * 680.0 * t) * np.exp(-t * 54.0) * 0.45
        wood = _fft_bandpass(rng.normal(0.0, 1.0, n), 900.0, 2900.0, sr) * np.exp(-t * 68.0) * 0.45
        return hit + wood
    snap = _fft_bandpass(rng.normal(0.0, 1.0, n), 850.0, 5600.0, sr) * np.exp(-t * 26.0) * 0.56
    crack = np.sin(2.0 * np.pi * 215.0 * t) * np.exp(-t * 36.0) * 0.28
    return snap + crack


def brass_horn(freq: float, dur: float, sr: int = SR) -> np.ndarray:
    """Bold medieval iron-banded hunting/battle horn blast."""
    n = int(sr * dur)
    t = np.arange(n) / sr
    vib = 1.0 + 0.004 * np.sin(2.0 * np.pi * 5.2 * t)
    ph = 2.0 * np.pi * np.cumsum(freq * vib) / sr
    tone = (
        0.52 * np.sin(ph)
        + 0.34 * np.sin(2.0 * ph + 0.2)
        + 0.22 * np.sin(3.0 * ph + 0.5)
        + 0.10 * np.sin(4.0 * ph)
    )
    env = np.minimum(1.0, t / 0.045) * np.minimum(1.0, (dur - t) / 0.14)
    return tone * np.maximum(0.0, env) * 0.26


def _place(buf: np.ndarray, start_sec: float, clip: np.ndarray, gain: float = 1.0, sr: int = SR):
    i0 = int(start_sec * sr)
    n = len(buf)
    for k in range(len(clip)):
        idx = (i0 + k) % n  # Wrap naturally for seamless looping!
        buf[idx] += clip[k] * gain


def _make_ambient_loops(audio_dir: str):
    dur = 16.0
    n = int(SR * dur)
    t = np.arange(n) / SR
    rng = np.random.default_rng(101)

    # ------------------------------------------------------------------
    # 1. amb_harbor.wav — Zwin Canal Lapping + Creaking Hull + D-Dorian Lute & Recorder
    # ------------------------------------------------------------------
    harbor = np.zeros(n, dtype=np.float64)
    raw_water = _fft_bandpass(rng.normal(0.0, 1.0, n), 140.0, 1100.0)
    swell = 0.55 + 0.45 * np.sin(2.0 * np.pi * t / 4.0)
    harbor += raw_water * (0.045 + 0.040 * swell)
    # Gentle distant mooring rope/timber creak twice per loop
    for ct in (3.2, 11.4):
        cn = int(SR * 0.45)
        tc = np.arange(cn) / SR
        creak = np.sin(2.0 * np.pi * (88.0 + 18.0 * np.sin(tc * 11.0)) * tc) * np.sin(np.pi * tc / 0.45)
        _place(harbor, ct, creak, 0.035)
    # D Dorian lute arpeggio (32 half-second beats = 16s)
    lute_notes = [
        293.66, 440.00, 349.23, 440.00, 523.25, 440.00, 392.00, 349.23,
        261.63, 392.00, 329.63, 392.00, 440.00, 392.00, 349.23, 329.63,
        293.66, 349.23, 440.00, 523.25, 587.33, 523.25, 440.00, 392.00,
        349.23, 329.63, 293.66, 261.63, 293.66, 329.63, 293.66, 220.00,
    ]
    for i, f in enumerate(lute_notes):
        _place(harbor, i * 0.5, karplus_strong(f, 1.15, 0.58, 0.996), 0.13)
        if i % 4 == 0:
            _place(harbor, i * 0.5, karplus_strong(f * 0.5, 1.8, 0.42, 0.997), 0.10)
    # Gentle wooden recorder melody phrasing in bars 2 and 4
    flute_phrases = [
        (4.0, 587.33, 0.9), (5.0, 523.25, 0.8), (6.0, 440.00, 1.5),
        (12.0, 523.25, 0.9), (13.0, 440.00, 0.8), (14.0, 392.00, 0.8), (14.8, 440.00, 1.1),
    ]
    for st, f, fd in flute_phrases:
        _place(harbor, st, wooden_flute(f, fd), 0.16)
    save_wav(audio_dir, "amb_harbor.wav", harbor)

    # ------------------------------------------------------------------
    # 2. amb_hearth.wav — Uncle Willem's Warm Cottage Hearth Crackles + Lute Lullaby
    # ------------------------------------------------------------------
    hearth = np.zeros(n, dtype=np.float64)
    fire_rumble = _fft_bandpass(rng.normal(0.0, 1.0, n), 70.0, 380.0)
    hearth += fire_rumble * 0.09
    # Realistic hearth crackles & pops
    for _ in range(95):
        pos = float(rng.uniform(0.0, 15.8))
        plen = int(SR * rng.uniform(0.008, 0.028))
        tp = np.arange(plen) / SR
        pop = _fft_bandpass(rng.normal(0.0, 1.0, plen), 1400.0, 5200.0) * np.exp(-tp * 140.0)
        _place(hearth, pos, pop, float(rng.uniform(0.05, 0.18)))
    hearth_notes = [
        293.66, 369.99, 440.00, 369.99, 329.63, 392.00, 493.88, 392.00,
        246.94, 293.66, 369.99, 293.66, 220.00, 293.66, 329.63, 293.66,
    ]
    for i, f in enumerate(hearth_notes):
        _place(hearth, i * 1.0, karplus_strong(f, 1.8, 0.50, 0.9965), 0.13)
        _place(hearth, i * 1.0 + 0.5, karplus_strong(f * 1.5, 1.0, 0.45, 0.995), 0.06)
    save_wav(audio_dir, "amb_hearth.wav", hearth)

    # ------------------------------------------------------------------
    # 3. amb_dawn_tension.wav — Cold Dawn Fog Wind + Distant Bell + Tense Viol Drone
    # ------------------------------------------------------------------
    dawn = np.zeros(n, dtype=np.float64)
    wind = _fft_bandpass(rng.normal(0.0, 1.0, n), 180.0, 720.0)
    wind_swell = 0.4 + 0.6 * np.sin(2.0 * np.pi * t / 8.0)
    dawn += wind * (0.04 + 0.05 * wind_swell)
    _place(dawn, 0.0, bowed_viol(146.83, 8.2), 0.22)
    _place(dawn, 8.0, bowed_viol(130.81, 8.2), 0.22)
    # Distant muffled Bruges church bell tolling twice
    _place(dawn, 1.5, bronze_bell(220.0, 4.0), 0.09)
    _place(dawn, 9.5, bronze_bell(220.0, 4.0), 0.08)
    for st, f in ((0.5, 293.66), (2.5, 349.23), (4.5, 329.63), (6.5, 277.18), (8.5, 293.66), (11.5, 311.13), (13.5, 261.63)):
        _place(dawn, st, karplus_strong(f, 1.6, 0.55, 0.996), 0.12)
    save_wav(audio_dir, "amb_dawn_tension.wav", dawn)

    # ------------------------------------------------------------------
    # 4. amb_sanctuary.wav — Mountain Gorge Wind + Brook + Noble Brotherhood Anthem
    # ------------------------------------------------------------------
    sanc = np.zeros(n, dtype=np.float64)
    brook = _fft_bandpass(rng.normal(0.0, 1.0, n), 450.0, 2600.0)
    sanc += brook * (0.032 + 0.015 * np.sin(2.0 * np.pi * t / 2.0))
    _place(sanc, 0.0, bowed_viol(196.00, 8.2), 0.16)
    _place(sanc, 8.0, bowed_viol(174.61, 8.2), 0.16)
    sanc_lute = [
        392.00, 440.00, 587.33, 440.00, 523.25, 493.88, 440.00, 392.00,
        349.23, 440.00, 523.25, 440.00, 392.00, 349.23, 329.63, 293.66,
    ]
    for i, f in enumerate(sanc_lute):
        _place(sanc, i * 1.0, karplus_strong(f, 1.6, 0.65, 0.996), 0.15)
        _place(sanc, i * 1.0 + 0.5, karplus_strong(f * 0.5, 1.0, 0.48, 0.996), 0.09)
    for st, f, fd in ((2.0, 587.33, 1.4), (6.0, 659.25, 1.6), (10.0, 523.25, 1.4), (13.5, 587.33, 2.0)):
        _place(sanc, st, wooden_flute(f, fd), 0.18)
    save_wav(audio_dir, "amb_sanctuary.wav", sanc)

    # ------------------------------------------------------------------
    # 5. amb_wilds.wav — Windswept Frontier Pine Wilds + Poignant Egg Motif
    # ------------------------------------------------------------------
    wilds = np.zeros(n, dtype=np.float64)
    pine_wind = _fft_bandpass(rng.normal(0.0, 1.0, n), 240.0, 1200.0)
    gust = 0.35 + 0.65 * np.sin(2.0 * np.pi * t / 5.3333)
    wilds += pine_wind * (0.045 + 0.055 * np.maximum(0.0, gust))
    _place(wilds, 0.0, bowed_viol(110.0, 8.2), 0.25)
    _place(wilds, 8.0, bowed_viol(130.81, 8.2), 0.24)
    for st, f in ((1.0, 440.0), (2.5, 392.0), (4.0, 329.63), (6.0, 349.23), (9.0, 440.0), (10.5, 523.25), (12.0, 493.88), (14.0, 392.0)):
        _place(wilds, st, karplus_strong(f, 2.0, 0.48, 0.997), 0.13)
    save_wav(audio_dir, "amb_wilds.wav", wilds)

    # ------------------------------------------------------------------
    # 6. amb_flight.wav — High-Altitude Wind + Wingbeats + Soaring Flight Theme
    # ------------------------------------------------------------------
    flight = np.zeros(n, dtype=np.float64)
    sky_wind = _fft_bandpass(rng.normal(0.0, 1.0, n), 320.0, 1850.0)
    flight += sky_wind * (0.045 + 0.03 * np.sin(2.0 * np.pi * t / 4.0))
    # Rhythmic deep dragon wingbeat pulse every 1.0s
    for beat_i in range(16):
        st = beat_i * 1.0
        wn = int(SR * 0.45)
        tw = np.arange(wn) / SR
        wflap = _fft_bandpass(rng.normal(0.0, 1.0, wn), 90.0, 420.0) * np.sin(np.pi * tw / 0.45) ** 1.4
        _place(flight, st, wflap, 0.24)
    _place(flight, 0.0, bowed_viol(220.0, 8.2), 0.14)
    _place(flight, 8.0, bowed_viol(196.0, 8.2), 0.14)
    flight_mel = [
        440.00, 523.25, 659.25, 587.33, 523.25, 659.25, 783.99, 659.25,
        392.00, 493.88, 587.33, 523.25, 440.00, 523.25, 659.25, 587.33,
    ]
    for i, f in enumerate(flight_mel):
        _place(flight, i * 1.0, karplus_strong(f, 1.4, 0.70, 0.996), 0.16)
        if i % 2 == 0:
            _place(flight, i * 1.0, wooden_flute(f, 1.5), 0.14)
    save_wav(audio_dir, "amb_flight.wav", flight)

    # ------------------------------------------------------------------
    # 7. amb_layer_pasture.wav — Sanctuary SE Pastures (Distant Sheep Bleats, Cow Low & Breeze)
    # ------------------------------------------------------------------
    pasture = _fft_bandpass(rng.normal(0.0, 1.0, n), 220.0, 1450.0) * (0.025 + 0.018 * np.sin(2.0 * np.pi * t / 4.0))
    for st, pitch in ((1.4, 218.0), (5.8, 246.0), (11.2, 198.0)):
        bn = int(SR * 0.52)
        tb = np.arange(bn) / SR
        vib = 1.0 + 0.045 * np.sin(2.0 * np.pi * 17.5 * tb)
        f_drop = pitch * (1.0 - 0.12 * tb / 0.52) * vib
        ph = 2.0 * np.pi * np.cumsum(f_drop) / SR
        bleat = (np.sin(ph) * 0.48 + np.sin(2.0 * ph) * 0.34 + np.sin(3.0 * ph) * 0.22 + np.sin(4.0 * ph) * 0.14)
        bleat *= np.minimum(1.0, tb / 0.04) * np.minimum(1.0, (0.52 - tb) / 0.10)
        _place(pasture, st, _fft_bandpass(bleat, 320.0, 1850.0), 0.36)
    # Distant soft cattle low & gentle brass collar bell
    mn = int(SR * 0.95)
    tm = np.arange(mn) / SR
    moo_ph = 2.0 * np.pi * np.cumsum(104.0 - 14.0 * tm / 0.95) / SR
    moo = (np.sin(moo_ph) * 0.55 + np.sin(2.0 * moo_ph) * 0.30) * np.sin(np.pi * tm / 0.95)
    _place(pasture, 8.2, _fft_bandpass(moo, 90.0, 520.0), 0.28)
    _place(pasture, 3.0, bronze_bell(740.0, 0.45), 0.10)
    _place(pasture, 12.6, bronze_bell(690.0, 0.45), 0.08)
    save_wav(audio_dir, "amb_layer_pasture.wav", pasture)

    # ------------------------------------------------------------------
    # 8. amb_layer_mess.wav — Sanctuary SW Mess & Stew Kettle (Bubbling Broth & Clinking Spoons)
    # ------------------------------------------------------------------
    mess = _fft_bandpass(rng.normal(0.0, 1.0, n), 75.0, 380.0) * 0.065
    for _ in range(72):
        pos = float(rng.uniform(0.0, 15.7))
        plen = int(SR * rng.uniform(0.015, 0.042))
        tp = np.arange(plen) / SR
        bf = float(rng.uniform(280.0, 620.0))
        bub = np.sin(2.0 * np.pi * (bf + 240.0 * tp / max(0.01, plen / SR)) * tp) * np.exp(-tp * 95.0)
        _place(mess, pos, bub, float(rng.uniform(0.08, 0.22)))
    for ct, freq in ((1.8, 1240.0), (2.05, 1380.0), (7.2, 1180.0), (11.5, 1320.0), (11.72, 1460.0), (14.4, 1210.0)):
        _place(mess, ct, bronze_bell(freq, 0.24), 0.16)
    save_wav(audio_dir, "amb_layer_mess.wav", mess)

    # ------------------------------------------------------------------
    # 9. amb_catacombs.wav — Louvain Vaulted Crypt (Ominous D-Phrygian Drones, Bells & Water Drips)
    # ------------------------------------------------------------------
    cat = np.zeros(n, dtype=np.float64)
    cavern_air = _fft_bandpass(rng.normal(0.0, 1.0, n), 55.0, 290.0)
    cat += cavern_air * (0.055 + 0.025 * np.sin(2.0 * np.pi * t / 8.0))
    # Deep dread bowed viol drones alternating D2 (73.42) -> Eb2 (77.78) tension shift
    _place(cat, 0.0, bowed_viol(73.42, 8.2), 0.28)
    _place(cat, 0.0, bowed_viol(146.83, 8.2), 0.12)
    _place(cat, 8.0, bowed_viol(77.78, 8.2), 0.29)
    _place(cat, 8.0, bowed_viol(155.56, 8.2), 0.13)
    # Slow anxious muffled heartbeat thump every 0.8s (75 BPM exact -> 20 beats = 16s loop)
    for bi in range(20):
        st = bi * 0.8
        _place(cat, st, frame_drum(54.0, 0.28), 0.18)
        if bi % 2 == 1:
            _place(cat, st + 0.22, frame_drum(48.0, 0.20), 0.10)
    # Echoing high crypt bell harmonics & echoing stone water drips
    for bt, freq, g in ((0.8, 440.0, 0.09), (4.8, 311.13, 0.10), (8.8, 466.16, 0.09), (12.8, 293.66, 0.11)):
        _place(cat, bt, bronze_bell(freq, 2.8), g)
    for dt in (1.9, 5.4, 7.1, 10.6, 14.3):
        dn = int(SR * 0.06)
        td = np.arange(dn) / SR
        drip = np.sin(2.0 * np.pi * (860.0 + 480.0 * td / 0.06) * td) * np.exp(-td * 52.0)
        _place(cat, dt, drip, 0.12)
    # Creeping Phrygian plucked harp motif (D-Eb-F-D-A-Bb-A-Eb)
    cat_notes = [
        (0.0, 293.66), (2.0, 311.13), (3.6, 349.23), (5.6, 293.66),
        (8.0, 311.13), (10.0, 440.00), (11.6, 466.16), (13.6, 349.23), (14.8, 311.13),
    ]
    for st, f in cat_notes:
        _place(cat, st, karplus_strong(f, 2.2, 0.42, 0.9975), 0.14)
    save_wav(audio_dir, "amb_catacombs.wav", cat)

    # ------------------------------------------------------------------
    # 10. amb_stealth.wav — Nocturnal Infiltration Stalk (120 BPM Tiptoe Pizzicato & Taut Viol)
    # ------------------------------------------------------------------
    stealth = np.zeros(n, dtype=np.float64)
    stealth += _fft_bandpass(rng.normal(0.0, 1.0, n), 140.0, 560.0) * 0.032
    _place(stealth, 0.0, bowed_viol(146.83, 8.2), 0.15)
    _place(stealth, 8.0, bowed_viol(138.59, 8.2), 0.15)
    # 120 BPM -> 64 quarter ticks (0.25s = eighth note) over 16s exact loop
    stealth_bass = [
        146.83, 146.83, 174.61, 164.81, 155.56, 146.83, 130.81, 110.00,
        146.83, 146.83, 174.61, 164.81, 196.00, 174.61, 155.56, 130.81,
    ]
    for i in range(64):
        st = i * 0.25
        # Soft tense wooden rim clockwork ticks on subdivisions
        if i % 2 == 0:
            _place(stealth, st, snare_tap(0.08, rim=True), 0.12 if (i % 4 == 0) else 0.06)
        elif i % 4 == 3:
            _place(stealth, st, snare_tap(0.07, rim=True), 0.05)
        # Tight damped walking pizzicato bass every 1.0s / 0.5s syncopation
        if i % 4 == 0:
            bf = stealth_bass[(i // 4) % len(stealth_bass)]
            _place(stealth, st, karplus_strong(bf, 0.42, 0.36, 0.985), 0.22)
        elif i % 4 == 2 and ((i // 4) % 2 == 1):
            bf = stealth_bass[(i // 4) % len(stealth_bass)] * 1.5
            _place(stealth, st, karplus_strong(bf, 0.35, 0.42, 0.986), 0.13)
    # Breathless flute caution lines on bars 4 & 8
    for st, f, fd in ((6.0, 523.25, 0.7), (6.75, 493.88, 0.8), (13.5, 466.16, 0.7), (14.25, 440.00, 1.1)):
        _place(stealth, st, wooden_flute(f, fd), 0.14)
    save_wav(audio_dir, "amb_stealth.wav", stealth)

    # ------------------------------------------------------------------
    # 11. amb_combat.wav — 150 BPM Uptempo Medieval Skirmish (80 exact eighth-steps in 16.0s)
    # ------------------------------------------------------------------
    combat = np.zeros(n, dtype=np.float64)
    # Sustained aggressive viol power-fifths per 4-bar phrase
    for bt, f in ((0.0, 146.83), (3.2, 116.54), (6.4, 130.81), (9.6, 110.00), (12.8, 130.81)):
        _place(combat, bt, bowed_viol(f, 3.3), 0.18)
        _place(combat, bt, bowed_viol(f * 1.5, 3.3), 0.10)
    # 150 BPM -> 0.4s quarter, 0.2s eighth note -> 80 steps = 16.000s exact!
    riff_notes = [
        293.66, 293.66, 440.00, 349.23, 392.00, 440.00, 523.25, 440.00,
        233.08, 233.08, 349.23, 293.66, 329.63, 349.23, 440.00, 349.23,
        261.63, 261.63, 392.00, 329.63, 349.23, 392.00, 466.16, 392.00,
        220.00, 293.66, 329.63, 440.00, 523.25, 466.16, 440.00, 329.63,
        293.66, 349.23, 440.00, 587.33, 523.25, 440.00, 392.00, 329.63,
    ]
    for s in range(80):
        st = s * 0.2
        bar_step = s % 8
        # Urgent bodhran war-drum kicks & snappy off-beat medieval snare
        if bar_step in (0, 3, 4):
            _place(combat, st, frame_drum(92.0 if bar_step == 0 else 78.0, 0.22), 0.28 if bar_step == 0 else 0.22)
        if bar_step in (2, 6, 7):
            _place(combat, st, snare_tap(0.12, rim=False), 0.20 if bar_step in (2, 6) else 0.13)
        if bar_step == 5 and (s // 8) % 2 == 1:
            _place(combat, st, snare_tap(0.09, rim=True), 0.15)
        # Driving fast plucked lute ostinato on every eighth beat
        rf = riff_notes[(s // 2) % len(riff_notes)] if s % 2 == 0 else riff_notes[(s // 2) % len(riff_notes)] * 1.5
        if s % 2 == 0:
            _place(combat, st, karplus_strong(rf, 0.45, 0.78, 0.991), 0.20)
            if bar_step in (0, 4):
                _place(combat, st, karplus_strong(rf * 0.5, 0.65, 0.60, 0.992), 0.17)
        else:
            _place(combat, st, karplus_strong(rf, 0.28, 0.72, 0.989), 0.11)
    # Battle horn stabs & frantic high recorder melody
    for ht, freq in ((0.0, 293.66), (3.2, 233.08), (6.4, 261.63), (9.6, 220.00), (12.8, 293.66)):
        _place(combat, ht, brass_horn(freq, 0.75), 0.28)
    for st, f, fd in (
        (1.6, 587.33, 0.35), (2.0, 659.25, 0.35), (2.4, 698.46, 0.55),
        (4.8, 523.25, 0.35), (5.2, 587.33, 0.35), (5.6, 659.25, 0.55),
        (8.0, 587.33, 0.35), (8.4, 698.46, 0.35), (8.8, 880.00, 0.65),
        (11.2, 659.25, 0.35), (11.6, 587.33, 0.35), (12.0, 523.25, 0.65),
        (14.4, 587.33, 0.35), (14.8, 659.25, 0.35), (15.2, 587.33, 0.65),
    ):
        _place(combat, st, wooden_flute(f, fd), 0.18)
    save_wav(audio_dir, "amb_combat.wav", combat)


def _make_footsteps(audio_dir: str):
    rng = np.random.default_rng(77)
    # 1. Cobble (crisp heel click + stone grit, 3 variants)
    for idx in (1, 2, 3):
        dur = 0.085
        n = int(SR * dur)
        t = np.arange(n) / SR
        f0 = 155.0 + idx * 14.0
        thud = np.sin(2.0 * np.pi * f0 * np.exp(-t * 16.0) * t) * np.exp(-t * 58.0) * 0.42
        grit = _fft_bandpass(rng.normal(0.0, 1.0, n), 1600.0, 4600.0) * np.exp(-t * 72.0) * 0.28
        sig = thud + grit
        save_wav(audio_dir, f"sfx_step_cobble_{idx}.wav", sig)
        if idx == 1:
            save_wav(audio_dir, "sfx_step.wav", sig)

    # 2. Wood (warm resonant oak plank thud, 3 variants)
    for idx in (1, 2, 3):
        dur = 0.10
        n = int(SR * dur)
        t = np.arange(n) / SR
        f0 = 105.0 + idx * 9.0
        plank = (
            np.sin(2.0 * np.pi * f0 * t) * 0.55
            + np.sin(2.0 * np.pi * f0 * 2.15 * t) * 0.22
        ) * np.exp(-t * 42.0)
        tap = _fft_bandpass(rng.normal(0.0, 1.0, n), 500.0, 1800.0) * np.exp(-t * 68.0) * 0.18
        save_wav(audio_dir, f"sfx_step_wood_{idx}.wav", plank + tap)

    # 3. Grass (soft rustling tuft + earth thump, 3 variants)
    for idx in (1, 2, 3):
        dur = 0.11
        n = int(SR * dur)
        t = np.arange(n) / SR
        thump = np.sin(2.0 * np.pi * (82.0 + idx * 6.0) * t) * np.exp(-t * 46.0) * 0.24
        rustle = _fft_bandpass(rng.normal(0.0, 1.0, n), 1800.0, 6200.0) * np.sin(np.pi * t / dur) * np.exp(-t * 24.0) * 0.24
        save_wav(audio_dir, f"sfx_step_grass_{idx}.wav", thump + rustle)


def _make_dialogue_voices(audio_dir: str):
    # Boy: crisp warm plucked syllable
    save_wav(audio_dir, "sfx_voice_boy.wav", karplus_strong(490.0, 0.065, 0.55, 0.985) * 0.45)
    save_wav(audio_dir, "sfx_blip.wav", karplus_strong(460.0, 0.060, 0.50, 0.985) * 0.42)

    # Female (Clara, Anna): soft airy flute-harp syllable
    save_wav(audio_dir, "sfx_voice_female.wav", wooden_flute(540.0, 0.070, 3.0) * 0.65)

    # Gruff older men (Uncle, Shipmaster, Quartermaster, Baker): warm low wood-marimba tap
    n = int(SR * 0.065)
    t = np.arange(n) / SR
    gruff = (np.sin(2.0 * np.pi * 220.0 * t) * 0.65 + np.sin(2.0 * np.pi * 440.0 * t) * 0.20) * np.exp(-t * 52.0) * 0.42
    save_wav(audio_dir, "sfx_voice_gruff.wav", gruff)

    # Stern (Inquisitor, Rider): clipped brassy reed pulse
    stern = (np.sin(2.0 * np.pi * 185.0 * t) * 0.5 + np.sin(2.0 * np.pi * 370.0 * t) * 0.25 + np.sin(2.0 * np.pi * 555.0 * t) * 0.15) * np.exp(-t * 45.0) * 0.35
    save_wav(audio_dir, "sfx_voice_stern.wav", stern)

    # Dragon (Black-Scaled Dragon): deep breathy resonant low syllable
    nd = int(SR * 0.14)
    td = np.arange(nd) / SR
    rng = np.random.default_rng(99)
    breath = _fft_bandpass(rng.normal(0.0, 1.0, nd), 120.0, 680.0) * 0.25
    hum = (np.sin(2.0 * np.pi * 88.0 * td) * 0.5 + np.sin(2.0 * np.pi * 132.0 * td) * 0.25) * 0.40
    env = np.sin(np.pi * td / 0.14)
    save_wav(audio_dir, "sfx_voice_dragon.wav", (breath + hum) * env)


def _make_gameplay_sfx(audio_dir: str):
    rng = np.random.default_rng(42)

    # 1. Rope throw whoosh + whip snap (0.28s)
    n = int(SR * 0.28)
    t = np.arange(n) / SR
    whoosh = _fft_bandpass(rng.normal(0.0, 1.0, n), 350.0, 2400.0) * np.sin(np.pi * np.minimum(1.0, t / 0.18)) * 0.38
    crack_env = np.exp(-np.abs(t - 0.14) * 55.0)
    crack = (_fft_bandpass(rng.normal(0.0, 1.0, n), 1500.0, 7500.0) * 0.55 + np.sin(2.0 * np.pi * 480.0 * t) * 0.35) * crack_env
    save_wav(audio_dir, "sfx_rope.wav", whoosh + crack)

    # 2. Winch-dash carabiner clink + fast rope reel (0.34s)
    n = int(SR * 0.34)
    t = np.arange(n) / SR
    clink = bronze_bell(1320.0, 0.34) * 0.45
    zip_sound = _fft_bandpass(rng.normal(0.0, 1.0, n), 700.0, 3600.0) * np.exp(-np.maximum(0.0, t - 0.05) * 10.0) * 0.32
    save_wav(audio_dir, "sfx_rope_winch.wav", clink + zip_sound)

    # 3. Knot Minigame Peg Click (0.09s)
    peg = karplus_strong(740.0, 0.09, 0.72, 0.99) * 0.45 + bronze_bell(1480.0, 0.09) * 0.25
    save_wav(audio_dir, "sfx_knot_peg.wav", peg)

    # 4. Knot Minigame Red Iron Snag Clang + Rope Fray (0.26s)
    n = int(SR * 0.26)
    t = np.arange(n) / SR
    clang = bronze_bell(340.0, 0.26) * 0.55 + bronze_bell(515.0, 0.26) * 0.35
    fray = _fft_bandpass(rng.normal(0.0, 1.0, n), 1200.0, 5200.0) * np.exp(-t * 22.0) * 0.40
    save_wav(audio_dir, "sfx_knot_snag.wav", clang + fray)

    # 5. Knot Fail Unraveling Snap (0.36s)
    n = int(SR * 0.36)
    t = np.arange(n) / SR
    drop = np.sin(2.0 * np.pi * (340.0 - 210.0 * t) * t) * np.exp(-t * 7.5) * 0.45
    save_wav(audio_dir, "sfx_knot_fail.wav", drop + karplus_strong(165.0, 0.36, 0.35, 0.992) * 0.35)

    # 6. Knot Cinch Leather Creak + Taut Lock Chord (0.38s)
    n = int(SR * 0.38)
    t = np.arange(n) / SR
    creak = np.sin(2.0 * np.pi * (145.0 + 220.0 * t) * t) * np.exp(-t * 14.0) * 0.35
    snap = np.zeros(n)
    _place(snap, 0.14, karplus_strong(587.33, 0.24, 0.75, 0.995), 0.40)
    _place(snap, 0.16, karplus_strong(880.00, 0.22, 0.75, 0.995), 0.35)
    save_wav(audio_dir, "sfx_knot_cinch.wav", creak + snap)

    # 7. Quest / Discovery Medieval Harp Fanfare Chime (0.95s)
    n = int(SR * 0.95)
    chime = np.zeros(n, dtype=np.float64)
    for st, f in ((0.0, 392.0), (0.09, 493.88), (0.18, 587.33), (0.28, 783.99)):
        _place(chime, st, karplus_strong(f, 0.65, 0.72, 0.9965), 0.35)
    _place(chime, 0.28, bronze_bell(783.99, 0.65), 0.15)
    save_wav(audio_dir, "sfx_chime.wav", chime)

    # 8. Rich Zwin Canal Water Splash + Droplet Bubbles (0.45s)
    n = int(SR * 0.45)
    t = np.arange(n) / SR
    plunge = _fft_bandpass(rng.normal(0.0, 1.0, n), 180.0, 2800.0) * np.exp(-t * 8.5) * 0.58
    bubbles = np.zeros(n)
    for bt, bf in ((0.08, 620.0), (0.14, 840.0), (0.21, 980.0), (0.29, 760.0)):
        bn = int(SR * 0.05)
        tb = np.arange(bn) / SR
        bub = np.sin(2.0 * np.pi * (bf + 260.0 * tb) * tb) * np.exp(-tb * 45.0)
        _place(bubbles, bt, bub, 0.22)
    save_wav(audio_dir, "sfx_splash.wav", plunge + bubbles)

    # 9. Wooden Crate Pickup / Drop (0.16s)
    n = int(SR * 0.16)
    t = np.arange(n) / SR
    thud = (np.sin(2.0 * np.pi * 110.0 * np.exp(-t * 14.0) * t) * 0.55) * np.exp(-t * 28.0)
    clack = _fft_bandpass(rng.normal(0.0, 1.0, n), 450.0, 1800.0) * np.exp(-t * 48.0) * 0.28
    save_wav(audio_dir, "sfx_crate_pickup.wav", thud + clack)

    # 10. Wooden Cottage Door Latch & Hinge Creak (0.34s)
    n = int(SR * 0.34)
    t = np.arange(n) / SR
    latch = _fft_bandpass(rng.normal(0.0, 1.0, n), 900.0, 3200.0) * np.exp(-t * 75.0) * 0.42
    hinge = np.sin(2.0 * np.pi * (190.0 + 45.0 * np.sin(t * 22.0)) * t) * np.sin(np.pi * np.clip((t - 0.06) / 0.26, 0.0, 1.0)) * 0.24
    save_wav(audio_dir, "sfx_door.wav", latch + hinge)

    # 11. Parchment Page Flip (Journal [Tab], 0.20s)
    n = int(SR * 0.20)
    t = np.arange(n) / SR
    paper = _fft_bandpass(rng.normal(0.0, 1.0, n), 1400.0, 6800.0) * np.sin(np.pi * t / 0.20) * 0.35
    save_wav(audio_dir, "sfx_journal.wav", paper)

    # 12. Subtle Wooden/Brass UI Click (0.05s)
    n = int(SR * 0.05)
    t = np.arange(n) / SR
    click = np.sin(2.0 * np.pi * 920.0 * t) * np.exp(-t * 110.0) * 0.30
    save_wav(audio_dir, "sfx_ui_click.wav", click)

    # 13. Bronze Ship's Bell when 'De Zwaan' docks (1.4s)
    bell = bronze_bell(440.0, 1.4) * 0.50
    _place(bell, 0.38, bronze_bell(440.0, 1.02), 0.45)
    save_wav(audio_dir, "sfx_ship_bell.wav", bell)

    # 14. Affectionate Dragon Purr/Trill (0.75s)
    n = int(SR * 0.75)
    t = np.arange(n) / SR
    mod = 0.65 + 0.35 * np.sin(2.0 * np.pi * 16.0 * t)
    purr = (np.sin(2.0 * np.pi * 76.0 * t) * 0.5 + np.sin(2.0 * np.pi * 114.0 * t) * 0.25) * mod * np.sin(np.pi * t / 0.75) * 0.45
    save_wav(audio_dir, "sfx_dragon_purr.wav", purr)

    # 15. Mournful Distant Dragon Cry / Sigh (1.2s)
    n = int(SR * 1.2)
    t = np.arange(n) / SR
    f_curve = 210.0 - 95.0 * (t / 1.2)
    phase = 2.0 * np.pi * np.cumsum(f_curve) / SR
    cry = (np.sin(phase) * 0.45 + np.sin(phase * 1.5) * 0.25 + np.sin(phase * 2.0) * 0.15)
    breath = _fft_bandpass(rng.normal(0.0, 1.0, n), 180.0, 950.0) * 0.16
    env = np.sin(np.pi * t / 1.2) ** 0.7
    save_wav(audio_dir, "sfx_dragon_cry.wav", (cry + breath) * env * 0.45)

    # 16. Campfire Warmth Egg-Glow Swell (0.65s)
    n = int(SR * 0.65)
    t = np.arange(n) / SR
    warm = (
        karplus_strong(329.63, 0.65, 0.55, 0.996) * 0.28
        + karplus_strong(493.88, 0.65, 0.55, 0.996) * 0.24
        + _fft_bandpass(rng.normal(0.0, 1.0, n), 400.0, 1800.0) * np.sin(np.pi * t / 0.65) * 0.18
    )
    save_wav(audio_dir, "sfx_campfire_warm.wav", warm)

    # 17. Dockworker's Knife Slash & Twine Snip (0.14s)
    n = int(SR * 0.14)
    t = np.arange(n) / SR
    swish = _fft_bandpass(rng.normal(0.0, 1.0, n), 1200.0, 6200.0) * np.sin(np.pi * t / 0.14) * 0.42
    edge = np.sin(2.0 * np.pi * (1450.0 - 700.0 * t / 0.14) * t) * np.exp(-t * 28.0) * 0.25
    save_wav(audio_dir, "sfx_slash.wav", swish + edge)

    # 18. Agile Dodge-Roll Whoosh (0.18s)
    n = int(SR * 0.18)
    t = np.arange(n) / SR
    dodge = _fft_bandpass(rng.normal(0.0, 1.0, n), 280.0, 1650.0) * np.sin(np.pi * t / 0.18) * 0.45
    save_wav(audio_dir, "sfx_dodge.wav", dodge)

    # 19. Heavy Dragon Wing-Beat Gust (0.42s)
    n = int(SR * 0.42)
    t = np.arange(n) / SR
    wb = _fft_bandpass(rng.normal(0.0, 1.0, n), 75.0, 520.0) * (np.sin(np.pi * t / 0.42) ** 1.3) * 0.62
    save_wav(audio_dir, "sfx_wing_beat.wav", wb)

    # 20. Hunter Ballista Torsion Twang (0.35s)
    n = int(SR * 0.35)
    t = np.arange(n) / SR
    twang = (np.sin(2.0 * np.pi * (95.0 + 35.0 * np.exp(-t * 10.0)) * t) * 0.55 + karplus_strong(110.0, 0.35, 0.45, 0.99) * 0.35) * np.exp(-t * 7.0)
    save_wav(audio_dir, "sfx_ballista.wav", twang)

    # 21. Crew Crossbow Bolt Fire (0.15s)
    n = int(SR * 0.15)
    t = np.arange(n) / SR
    snap = karplus_strong(440.0, 0.15, 0.85, 0.985) * 0.42
    whistle = np.sin(2.0 * np.pi * (1600.0 - 900.0 * t / 0.15) * t) * np.exp(-t * 24.0) * 0.25
    save_wav(audio_dir, "sfx_bolt.wav", snap + whistle)

    # 22. Wood/Strap Impact Thud (0.20s)
    n = int(SR * 0.20)
    t = np.arange(n) / SR
    impact = np.sin(2.0 * np.pi * (140.0 * np.exp(-t * 15.0)) * t) * np.exp(-t * 18.0) * 0.60
    splinter = _fft_bandpass(rng.normal(0.0, 1.0, n), 700.0, 3400.0) * np.exp(-t * 26.0) * 0.45
    save_wav(audio_dir, "sfx_hit_thud.wav", impact + splinter)

    # 23. Church Watchman / Hunter Brass Alert Bugle (0.55s)
    n = int(SR * 0.55)
    alert = np.zeros(n)
    _place(alert, 0.0, bronze_bell(523.25, 0.26), 0.35)
    _place(alert, 0.20, bronze_bell(659.25, 0.35), 0.42)
    save_wav(audio_dir, "sfx_alert_horn.wav", alert)

    # 24. Eggshell Fracture Crack & Amber Shimmer (0.28s)
    n = int(SR * 0.28)
    t = np.arange(n) / SR
    crack = _fft_bandpass(rng.normal(0.0, 1.0, n), 1400.0, 5600.0) * np.exp(-t * 32.0) * 0.65
    snap2 = _fft_bandpass(rng.normal(0.0, 1.0, n), 1800.0, 6200.0) * np.exp(-np.maximum(0.0, t - 0.07) * 38.0) * (t >= 0.07) * 0.48
    pop = np.sin(2.0 * np.pi * (420.0 + 180.0 * np.exp(-t * 18.0)) * t) * np.exp(-t * 18.0) * 0.28
    save_wav(audio_dir, "sfx_egg_crack.wav", crack + snap2 + pop)

    # 25. Hatchling First Chirp & Trill (0.45s)
    n = int(SR * 0.45)
    t = np.arange(n) / SR
    f1 = 760.0 + 340.0 * np.sin(np.minimum(1.0, t / 0.14) * np.pi)
    f2 = 880.0 + 420.0 * np.sin(np.clip((t - 0.20) / 0.18, 0.0, 1.0) * np.pi)
    env1 = np.exp(-np.abs(t - 0.08) * 18.0) * (t < 0.19)
    env2 = np.exp(-np.abs(t - 0.30) * 14.0) * (t >= 0.18)
    chirp = (np.sin(2.0 * np.pi * np.cumsum(f1) / SR) * env1 * 0.42 + np.sin(2.0 * np.pi * np.cumsum(f2) / SR) * env2 * 0.46)
    trill = np.sin(2.0 * np.pi * 1560.0 * t) * (env1 + env2) * 0.14
    save_wav(audio_dir, "sfx_hatch_chirp.wav", chirp + trill)

    # 26. Iron Cage Snap & Clatter (0.42s)
    n = int(SR * 0.42)
    t = np.arange(n) / SR
    crunch = _fft_bandpass(rng.normal(0.0, 1.0, n), 900.0, 5400.0) * np.exp(-t * 16.0) * 0.55
    ring = np.zeros(n)
    _place(ring, 0.0, bronze_bell(615.0, 0.25), 0.34)
    _place(ring, 0.11, bronze_bell(840.0, 0.22), 0.26)
    _place(ring, 0.21, bronze_bell(490.0, 0.20), 0.22)
    save_wav(audio_dir, "sfx_cage_break.wav", crunch + ring)

    # 27. Oak Block Cleaver Chop (0.16s)
    n = int(SR * 0.16)
    t = np.arange(n) / SR
    chop_thud = np.sin(2.0 * np.pi * (125.0 * np.exp(-t * 18.0)) * t) * np.exp(-t * 24.0) * 0.65
    cleave_edge = _fft_bandpass(rng.normal(0.0, 1.0, n), 1100.0, 4800.0) * np.exp(-t * 34.0) * 0.45
    save_wav(audio_dir, "sfx_butcher_chop.wav", chop_thud + cleave_edge)

    # 28. Dragon Happy Chomp & Throat Rumble (0.48s)
    n = int(SR * 0.48)
    t = np.arange(n) / SR
    bite = _fft_bandpass(rng.normal(0.0, 1.0, n), 240.0, 1650.0) * np.exp(-t * 22.0) * 0.55
    rumble = (np.sin(2.0 * np.pi * (82.0 + 18.0 * np.sin(2.0 * np.pi * 12.0 * t)) * t) * 0.45 + np.sin(2.0 * np.pi * 124.0 * t) * 0.20) * np.minimum(1.0, t / 0.05) * np.exp(-t * 4.2)
    save_wav(audio_dir, "sfx_dragon_chomp.wav", bite + rumble)

    # 29. St. Donatian Cathedral Deep Bronze Bell Toll (2.4s)
    church_bell = (
        bronze_bell(220.0, 2.4) * 0.52
        + bronze_bell(440.0, 2.4) * 0.25
        + bronze_bell(110.0, 2.4) * 0.28
    )
    save_wav(audio_dir, "sfx_church_bell.wav", church_bell)

    # 30. Bakery Brick Oven Cozy Crackle & Ember Pop (0.72s)
    n = int(SR * 0.72)
    t = np.arange(n) / SR
    hearth_hum = _fft_bandpass(rng.normal(0.0, 1.0, n), 140.0, 460.0) * np.sin(np.pi * t / 0.72) * 0.28
    crackles = np.zeros(n)
    for pt in (0.06, 0.19, 0.28, 0.44, 0.57, 0.65):
        pn = int(SR * 0.035)
        tp = np.arange(pn) / SR
        pop = _fft_bandpass(rng.normal(0.0, 1.0, pn), 1600.0, 5600.0) * np.exp(-tp * 95.0)
        _place(crackles, pt, pop, 0.48)
    save_wav(audio_dir, "sfx_oven_crackle.wav", hearth_hum + crackles)

    # 31. Hatching Eggshell Tremor Rumble & Amber Glow Strain (0.85s)
    n = int(SR * 0.85)
    t = np.arange(n) / SR
    f_rumb = 62.0 - 18.0 * (t / 0.85)
    ph_r = 2.0 * np.pi * np.cumsum(f_rumb) / SR
    body_throb = (np.sin(ph_r) * 0.55 + np.sin(ph_r * 2.0) * 0.25) * np.sin(np.pi * t / 0.85)
    grit = _fft_bandpass(rng.normal(0.0, 1.0, n), 110.0, 520.0) * np.sin(np.pi * t / 0.85) * 0.24
    creaks = np.zeros(n)
    for ct in (0.14, 0.42, 0.68):
        cn = int(SR * 0.05)
        tc = np.arange(cn) / SR
        _place(creaks, ct, _fft_bandpass(rng.normal(0.0, 1.0, cn), 950.0, 3200.0) * np.exp(-tc * 45.0), 0.32)
    save_wav(audio_dir, "sfx_hatch_rumble.wav", (body_throb + grit) * 0.55 + creaks)

    # 32. Golden Hatchling Awakening Resonance & Wing Unfurl Swell (1.55s)
    n = int(SR * 1.55)
    t = np.arange(n) / SR
    env_a = np.minimum(1.0, t / 0.14) * np.exp(-np.maximum(0.0, t - 0.14) * 1.75)
    chord = (
        karplus_strong(293.66, 1.55, 0.65, 0.997) * 0.30
        + karplus_strong(440.00, 1.55, 0.65, 0.997) * 0.26
        + karplus_strong(587.33, 1.55, 0.60, 0.996) * 0.22
        + np.sin(2.0 * np.pi * 880.0 * t) * env_a * 0.14
    )
    gust = _fft_bandpass(rng.normal(0.0, 1.0, n), 160.0, 1400.0) * np.exp(-t * 3.8) * 0.28
    save_wav(audio_dir, "sfx_hatch_awakening.wav", chord + gust)


def _make_cutscene_motifs(audio_dir: str):
    """Non-looping emotional cutscene swell cues (placed directly via SoundManager motif_player)."""
    # mus_hatch_awakening.wav — Gentle 8.8s Harp/Lute & Flute Awaken-Bond Resolve (D minor -> warm D Major)
    dur = 8.8
    n = int(SR * dur)
    t = np.arange(n) / SR
    motif = np.zeros(n, dtype=np.float64)
    # Warm gentle viol pad underneath resolving from Bb/D -> A -> bright D Major
    _place(motif, 0.0, bowed_viol(146.83, 4.6), 0.20)
    _place(motif, 0.0, bowed_viol(220.00, 4.6), 0.14)
    _place(motif, 4.2, bowed_viol(146.83, 4.4), 0.22)
    _place(motif, 4.2, bowed_viol(185.00, 4.4), 0.16)  # F#3 sunlit major third!
    _place(motif, 4.2, bowed_viol(220.00, 4.4), 0.14)
    # Sweeping gentle harp / lute arpeggio bloom
    harp = [
        (0.05, 293.66), (0.35, 440.00), (0.65, 587.33), (1.05, 523.25),
        (1.65, 349.23), (1.95, 440.00), (2.25, 587.33), (2.75, 659.25),
        (3.40, 293.66), (3.70, 369.99), (4.00, 440.00), (4.30, 587.33), (4.60, 739.99), (5.05, 880.00),
        (5.75, 392.00), (6.05, 493.88), (6.35, 587.33), (6.80, 739.99), (7.30, 587.33),
    ]
    for st, f in harp:
        _place(motif, st, karplus_strong(f, 2.2, 0.62, 0.9972), 0.19)
        if st in (0.05, 1.65, 3.40, 5.75):
            _place(motif, st, karplus_strong(f * 0.5, 2.6, 0.45, 0.9975), 0.14)
    # Tender singing recorder/flute melody during the palm imprint
    for st, f, fd in ((1.15, 587.33, 1.15), (2.35, 659.25, 1.10), (3.55, 739.99, 1.45), (5.15, 880.00, 1.30), (6.50, 739.99, 1.90)):
        _place(motif, st, wooden_flute(f, fd), 0.18)
    # Smooth fade-in and tail so it ends softly
    att = min(n, int(SR * 0.18))
    rel = min(n, int(SR * 0.65))
    motif[:att] *= np.linspace(0.0, 1.0, att)
    motif[-rel:] *= np.linspace(1.0, 0.0, rel)
    save_wav(audio_dir, "mus_hatch_awakening.wav", motif)


def generate_all_audio(audio_dir: str):
    _make_ambient_loops(audio_dir)
    _make_cutscene_motifs(audio_dir)
    _make_footsteps(audio_dir)
    _make_dialogue_voices(audio_dir)
    _make_gameplay_sfx(audio_dir)

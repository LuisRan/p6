import 'dart:math';
import 'dart:typed_data';

/// Una nota: frecuencia (Hz) y duración (s).
class Note {
  const Note(this.freq, this.seconds);
  final double freq;
  final double seconds;
}

/// Sintetiza un WAV PCM 16-bit mono a partir de notas (onda senoidal con
/// un poco de armónico y envolvente ADSR simple para evitar "clicks").
/// No requiere assets: todo se genera en memoria.
Uint8List synthWav(List<Note> notes, {int sampleRate = 22050, double volume = 0.6}) {
  final samples = <int>[];
  for (final n in notes) {
    final count = (n.seconds * sampleRate).round();
    for (var i = 0; i < count; i++) {
      final t = i / sampleRate;
      final pos = i / count;
      // Envolvente: ataque 8%, decaimiento exponencial.
      final env = (pos < 0.08 ? pos / 0.08 : exp(-3.0 * (pos - 0.08)));
      final v = n.freq <= 0
          ? 0.0
          : (sin(2 * pi * n.freq * t) + 0.3 * sin(4 * pi * n.freq * t)) / 1.3;
      samples.add((v * env * volume * 32767).round().clamp(-32768, 32767));
    }
  }
  final dataLen = samples.length * 2;
  final bd = ByteData(44 + dataLen);
  void str(int off, String s) {
    for (var i = 0; i < s.length; i++) {
      bd.setUint8(off + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  bd.setUint32(4, 36 + dataLen, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  bd.setUint32(16, 16, Endian.little); // tamaño del bloque fmt
  bd.setUint16(20, 1, Endian.little); // PCM
  bd.setUint16(22, 1, Endian.little); // mono
  bd.setUint32(24, sampleRate, Endian.little);
  bd.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  bd.setUint16(32, 2, Endian.little); // block align
  bd.setUint16(34, 16, Endian.little); // bits
  str(36, 'data');
  bd.setUint32(40, dataLen, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    bd.setInt16(44 + i * 2, samples[i], Endian.little);
  }
  return bd.buffer.asUint8List();
}

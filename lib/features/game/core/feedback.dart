import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'settings.dart';
import 'wav_synth.dart';

/// Efectos disponibles.
enum Sfx { tap, connect, win, lose, save }

/// Retroalimentación sonora (WAV sintetizados en memoria) y háptica.
/// Todo envuelto en try/catch: en tests o plataformas sin audio no falla.
class GameFeedback {
  GameFeedback(this.settings);
  final AppSettings settings;

  final Map<Sfx, Uint8List> _wavs = {
    Sfx.tap: synthWav(const [Note(520, 0.06)]),
    Sfx.connect: synthWav(const [Note(660, 0.07), Note(880, 0.10)]),
    Sfx.win: synthWav(const [
      Note(523, 0.12), Note(659, 0.12), Note(784, 0.12), Note(1046, 0.30),
    ]),
    Sfx.lose: synthWav(const [Note(330, 0.18), Note(262, 0.18), Note(196, 0.35)]),
    Sfx.save: synthWav(const [Note(740, 0.08), Note(988, 0.12)]),
  };
  final Map<Sfx, AudioPlayer> _players = {};

  Future<void> play(Sfx sfx) async {
    if (!settings.sound) return;
    try {
      final player = _players.putIfAbsent(sfx, () => AudioPlayer());
      await player.stop();
      await player.play(BytesSource(_wavs[sfx]!, mimeType: 'audio/wav'),
          volume: 0.8);
    } catch (_) {
      // Sin audio disponible: se ignora silenciosamente.
    }
  }

  /// Vibración ligera / media / fuerte según el evento.
  Future<void> haptic({bool strong = false, bool selection = false}) async {
    if (!settings.vibration) return;
    try {
      if (selection) {
        await HapticFeedback.selectionClick();
      } else if (strong) {
        await HapticFeedback.heavyImpact();
      } else {
        await HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
  }
}

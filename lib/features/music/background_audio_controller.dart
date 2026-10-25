import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/local/models.dart';

/// Layanan pemutar audio latar dengan `just_audio` dan `audio_session` (Bagian 6.7 & 9 PRD, Bagian 10 `design.md`):
/// - Memutar track bebas royalti dari `assets/audio/` atau file milik pengguna.
/// - Mengonfigurasi `AudioSession` dengan *audio ducking* otomatis saat ada notifikasi atau panggilan telepon.
/// - Tetap aman (tidak crash) apabila dijalankan di lingkungan widget test tanpa audio hardware.
class BackgroundAudioController {
  BackgroundAudioController() {
    _initSession();
  }

  AudioPlayer? _player;

  Future<void> _initSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.mixWithOthers |
              AVAudioSessionCategoryOptions.duckOthers,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType:
              AndroidAudioFocusGainType.gainTransientMayDuck,
        ),
      );
      _player = AudioPlayer();
      await _player?.setLoopMode(LoopMode.one);
    } catch (_) {
      // Aman di lingkungan test tanpa native plugin
    }
  }

  Future<void> playTrack(MusicTrackModel track) async {
    try {
      if (_player == null) await _initSession();
      if (track.sourceType == 'bundled') {
        await _player?.setAsset(track.uri);
      } else {
        await _player?.setFilePath(track.uri);
      }
      await _player?.play();
    } catch (_) {}
  }

  Future<void> pause() async {
    try {
      await _player?.pause();
    } catch (_) {}
  }

  Future<void> setVolume(double volume) async {
    try {
      await _player?.setVolume(volume.clamp(0.0, 1.0));
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _player?.dispose();
    } catch (_) {}
  }
}

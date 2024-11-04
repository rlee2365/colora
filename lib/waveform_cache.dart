import 'package:colora/models.dart';
import 'package:colora/objectbox.g.dart';

class WaveformCache {
  Box<CachedWaveform>? box;
  final Map<(String, int), CachedWaveform> _cache = {};

  Future<void> setup(Store store) async {
    box = store.box<CachedWaveform>();
    for (final cachedWaveform in box!.getAll()) {
      _cache[(cachedWaveform.fnv1aHash, cachedWaveform.noOfSamples)] =
          cachedWaveform;
    }
  }

  CachedWaveform? get({required String fnv1aHash, required int noOfSamples}) {
    if (_cache.containsKey((fnv1aHash, noOfSamples))) {
      // print("Got waveform: $path $noOfSamples");
      return _cache[(fnv1aHash, noOfSamples)];
    }
    // print("No match: $path $noOfSamples");
    return null;
  }

  CachedWaveform set(
      {required String fnv1aHash,
      required int noOfSamples,
      required List<double> waveform}) {
    final boxWaveform = CachedWaveform();
    boxWaveform.fnv1aHash = fnv1aHash;
    boxWaveform.noOfSamples = noOfSamples;
    boxWaveform.waveform = waveform;
    _cache[(fnv1aHash, noOfSamples)] = boxWaveform;
    boxWaveform.id = box!.put(boxWaveform);
    // print("Stored waveform: $fnv1aHash $noOfSamples");
    return boxWaveform;
  }
}

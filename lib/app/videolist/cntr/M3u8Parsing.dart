import 'dart:io';
import 'package:http/http.dart' as http;

class M3U8Parser {
  static Future<String> getLowestQualityStreamUrl(String masterPlaylistUrl) async {
    final response = await http.get(Uri.parse(masterPlaylistUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to load master playlist');
    }

    final lines = response.body.split('\n');
    String? audioStreamUrl;
    List<Map<String, dynamic>> videoStreams = [];

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('#EXT-X-MEDIA:TYPE=AUDIO')) {
        final uriMatch = RegExp(r'URI="([^"]*)"').firstMatch(lines[i]);
        if (uriMatch != null) {
          audioStreamUrl = _resolveUrl(masterPlaylistUrl, uriMatch.group(1)!);
        }
      } else if (lines[i].startsWith('#EXT-X-STREAM-INF')) {
        final resolutionMatch = RegExp(r'RESOLUTION=(\d+x\d+)').firstMatch(lines[i]);
        final bandwidthMatch = RegExp(r'BANDWIDTH=(\d+)').firstMatch(lines[i]);

        if (resolutionMatch != null && bandwidthMatch != null && i + 1 < lines.length) {
          videoStreams.add({
            'resolution': resolutionMatch.group(1)!,
            'bandwidth': int.parse(bandwidthMatch.group(1)!),
            'url': _resolveUrl(masterPlaylistUrl, lines[i + 1].trim()),
          });
        }
      }
    }

    if (videoStreams.isEmpty) {
      throw Exception('No video streams found in the master playlist');
    }

    // Sort by bandwidth (ascending) to get the lowest quality stream
    videoStreams.sort((a, b) => a['bandwidth'].compareTo(b['bandwidth']));
    String lowestQualityStreamUrl = videoStreams.first['url'];

    // If we're on Android, replace 'm3u8' with 'mpd'
    if (Platform.isAndroid) {
      lowestQualityStreamUrl = lowestQualityStreamUrl.replaceAll('m3u8', 'mpd');
    }

    return lowestQualityStreamUrl;
  }

  static String _resolveUrl(String base, String relative) {
    return Uri.parse(base).resolve(relative).toString();
  }
}

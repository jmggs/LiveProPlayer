import 'dart:io';
import 'package:xml/xml.dart';
import '../models/track.dart';

/// Saves and loads playlists as XML files, compatible with the desktop format.
class PlaylistService {
  Future<void> savePlaylist(List<Track> tracks, String filePath) async {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('playlist', nest: () {
      builder.attribute('version', '1');
      for (final track in tracks) {
        builder.element('track', nest: () {
          builder.element('path', nest: track.path);
          builder.element('name', nest: track.displayName);
          builder.element('duration', nest: track.duration.inMilliseconds.toString());
        });
      }
    });

    final xmlDoc = builder.buildDocument();
    await File(filePath).writeAsString(xmlDoc.toXmlString(pretty: true));
  }

  Future<List<Track>> loadPlaylist(String filePath) async {
    final content = await File(filePath).readAsString();
    final document = XmlDocument.parse(content);
    final tracks = <Track>[];

    for (final node in document.findAllElements('track')) {
      final path     = node.findElements('path').firstOrNull?.innerText ?? '';
      final name     = node.findElements('name').firstOrNull?.innerText ?? '';
      final durMs    = int.tryParse(
        node.findElements('duration').firstOrNull?.innerText ?? '0',
      ) ?? 0;

      if (path.isNotEmpty && File(path).existsSync()) {
        tracks.add(Track(
          path:        path,
          displayName: name.isNotEmpty ? name : path.split('/').last,
          duration:    Duration(milliseconds: durMs),
        ));
      }
    }

    return tracks;
  }
}

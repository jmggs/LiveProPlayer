import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

typedef RemoteCallback = void Function(String command);

/// HTTP server that exposes the same endpoints as the desktop version.
/// Default port: 8000
/// Endpoints: /play  /pause  /stop  /next  /previous  /cue  /up  /down
class RemoteService {
  HttpServer? _server;
  int         _port;
  bool        get isRunning => _server != null;
  int         get port      => _port;

  RemoteService({int port = 8000}) : _port = port;

  Future<bool> start(RemoteCallback onCommand) async {
    if (_server != null) await stop();

    try {
      final router = Router();

      Handler handle(String cmd) => (Request req) {
        onCommand(cmd);
        return Response.ok(
          '{"status":"ok","command":"$cmd"}',
          headers: {'Content-Type': 'application/json'},
        );
      };

      router.get('/play',     handle('play'));
      router.get('/pause',    handle('pause'));
      router.get('/stop',     handle('stop'));
      router.get('/next',     handle('next'));
      router.get('/previous', handle('previous'));
      router.get('/cue',      handle('cue'));
      router.get('/up',       handle('up'));
      router.get('/down',     handle('down'));
      router.get('/status',   (Request req) {
        // Returns 200 OK as a health check
        return Response.ok(
          '{"status":"running","port":$_port}',
          headers: {'Content-Type': 'application/json'},
        );
      });

      final handler = const Pipeline()
          .addMiddleware(logRequests())
          .addHandler(router.call);

      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, _port);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> changePort(int port) async {
    _port = port;
  }
}

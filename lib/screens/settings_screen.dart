import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _portCtrl;

  @override
  void initState() {
    super.initState();
    final p = context.read<PlayerProvider>();
    _portCtrl = TextEditingController(text: p.remotePort.toString());
  }

  @override
  void dispose() {
    _portCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PlayerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Remote Control ───────────────────────────────────────────────
          const _SectionHeader('HTTP REMOTE CONTROL'),
          const SizedBox(height: 12),

          Row(
            children: [
              const Text('Enable Remote',
                  style: TextStyle(color: AppTheme.text, fontSize: 15)),
              const Spacer(),
              Switch(
                value:    p.remoteEnabled,
                onChanged: (_) => p.toggleRemote(),
                activeThumbColor: const Color(0xFF00CC00),
              ),
            ],
          ),

          if (p.remoteEnabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Port:',
                    style: TextStyle(color: AppTheme.text, fontSize: 14)),
                const SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _portCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: AppTheme.text),
                    decoration: _inputDecoration(),
                    onSubmitted: (v) {
                      final port = int.tryParse(v);
                      if (port != null && port > 0 && port < 65536) {
                        p.setRemotePort(port);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (p.deviceIp.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:        AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Remote Control URLs',
                        style: TextStyle(
                            color: AppTheme.textDim, fontSize: 12,
                            letterSpacing: 1)),
                    const SizedBox(height: 8),
                    _UrlRow('http://${p.deviceIp}:${p.remotePort}/play'),
                    _UrlRow('http://${p.deviceIp}:${p.remotePort}/pause'),
                    _UrlRow('http://${p.deviceIp}:${p.remotePort}/stop'),
                    _UrlRow('http://${p.deviceIp}:${p.remotePort}/next'),
                    _UrlRow('http://${p.deviceIp}:${p.remotePort}/cue'),
                  ],
                ),
              ),
          ],

          const SizedBox(height: 32),

          // ── About ────────────────────────────────────────────────────────
          const _SectionHeader('ABOUT'),
          const SizedBox(height: 12),
          const Text(
            'Live Pro Player  v1.8.0\n'
            'Flutter port of the desktop LiveProPlayer.\n\n'
            'Supports WAV · MP3 · FLAC · AIFF',
            style: TextStyle(color: AppTheme.textDim, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration() => InputDecoration(
    isDense:  true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    filled:   true,
    fillColor: AppTheme.surfaceHigh,
    border:    OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none),
  );
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppTheme.textDim,
      fontSize: 12,
      letterSpacing: 1.5,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _UrlRow extends StatelessWidget {
  final String url;
  const _UrlRow(this.url);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Clipboard.setData(ClipboardData(text: url)),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(url,
          style: const TextStyle(
              color: Color(0xFF4499FF), fontSize: 12,
              fontFamily: 'monospace')),
    ),
  );
}

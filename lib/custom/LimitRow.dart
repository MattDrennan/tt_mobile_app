import 'package:flutter/material.dart';

class LimitRow extends StatelessWidget {
  final String? total; // Overall trooper/handler limit
  final String? clubs; // Breakdown of clubs (may contain \n or <b>…</b>)
  final String? extra; // Optional extra notes if needed

  const LimitRow({
    super.key,
    this.total,
    this.clubs,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    // Combine total, clubs, and extra into one block of lines
    final combined = _combine(total, clubs, extra);
    final lines = _splitLines(combined);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lines.isEmpty)
            const Text('N/A')
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines
                  .map(
                    (line) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("• "),
                        Expanded(child: Text(line.trim(), softWrap: true)),
                      ],
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  /// Join all parts with newlines if they exist
  String _combine(String? total, String? clubs, String? extra) {
    final parts = <String>[
      if (total != null && total.trim().isNotEmpty) total,
      if (clubs != null && clubs.trim().isNotEmpty) clubs,
      if (extra != null && extra.trim().isNotEmpty) extra,
    ];
    return parts.join('\n');
  }

  /// Split on both real and escaped newlines
  List<String> _splitLines(String text) {
    if (text.isEmpty) return [];
    return text
        .replaceAll(r'\n', '\n') // handle escaped newlines from backend
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

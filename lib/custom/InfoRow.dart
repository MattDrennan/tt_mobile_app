import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String? value; // Allow nullable values
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const InfoRow({
    Key? key,
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
  }) : super(key: key);

  bool _isValidUrl(String url) {
    final urlPattern =
        r'^(https?:\/\/)?([\w\-]+\.)+[\w\-]+(\/[\w\-.,@?^=%&:/~+#]*)?$';
    final regExp = RegExp(urlPattern, caseSensitive: false);
    return regExp.hasMatch(url);
  }

  void _launchUrl(BuildContext context, String url) async {
    // Ensure the URL has a valid scheme
    final fullUrl = url.startsWith('http') ? url : 'https://$url';
    if (await canLaunch(fullUrl)) {
      await launch(fullUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the link: $fullUrl')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if the value is null or empty, and default to "N/A"
    final displayValue = (value?.isEmpty ?? true) ? 'N/A' : value!;
    final isLink = _isValidUrl(displayValue);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: labelStyle ?? const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: isLink
                ? GestureDetector(
                    onTap: () => _launchUrl(context, displayValue),
                    child: Text(
                      displayValue,
                      style: valueStyle ??
                          const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  )
                : Text(
                    displayValue,
                    style: valueStyle ?? const TextStyle(color: Colors.grey),
                  ),
          ),
        ],
      ),
    );
  }
}

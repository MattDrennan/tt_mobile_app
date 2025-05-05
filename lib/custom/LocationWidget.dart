import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:maps_launcher/maps_launcher.dart';

class LocationWidget extends StatelessWidget {
  final String? location;

  const LocationWidget({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    // Unescape HTML entities
    final unescape = HtmlUnescape();

    final locationText = unescape.convert(location ?? 'No location provided.');

    return GestureDetector(
      onTap: () {
        if (locationText.isNotEmpty &&
            locationText != 'No location provided.') {
          MapsLauncher.launchQuery(locationText);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No valid location to open.')),
          );
        }
      },
      child: Text(
        locationText,
        style: const TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html_unescape/html_unescape.dart';

class LocationWidget extends StatelessWidget {
  final String? location;

  const LocationWidget({Key? key, required this.location}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Unescape HTML entities
    final unescape = HtmlUnescape();

    final locationText = unescape.convert(location ?? 'No location provided.');

    return GestureDetector(
      onTap: () async {
        if (locationText.isNotEmpty &&
            locationText != 'No location provided.') {
          final query = Uri.encodeComponent(locationText);
          final googleMapsUrl =
              'https://www.google.com/maps/search/?api=1&query=$query';

          if (await canLaunch(googleMapsUrl)) {
            await launch(googleMapsUrl);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Could not open Google Maps for $locationText')),
            );
          }
        }
      },
      child: Text(
        "$locationText",
        style: const TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

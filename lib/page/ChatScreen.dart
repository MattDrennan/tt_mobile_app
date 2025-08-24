import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view_gallery.dart';
import 'dart:convert';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart' as imagePicker;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:photo_view/photo_view.dart';
import 'package:hive/hive.dart';
import 'package:tt_mobile_app/custom/AppBar.dart';
import 'package:tt_mobile_app/custom/Functions.dart';

class ChatScreen extends StatefulWidget {
  final String troopName;
  final int threadId;
  final int postId;

  const ChatScreen({
    super.key,
    required this.troopName,
    required this.threadId,
    required this.postId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<types.Message> _messages = [];
  final imagePicker.ImagePicker _picker = imagePicker.ImagePicker();
  Timer? _timer; // Timer for polling

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _startMessagePolling(); // Start periodic updates
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer on exit
    super.dispose();
  }

  void _startMessagePolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      _fetchMessages(); // Fetch messages periodically
    });
  }

  Future<void> _fetchMessages() async {
    final response = await http.get(
      Uri.parse(
          '${dotenv.env['FORUM_URL'].toString()}api/threads/${widget.threadId}?with_posts=true&page=1'),
      headers: {
        'XF-Api-Key': dotenv.env['API_KEY'].toString(),
        'XF-Api-User': dotenv.env['API_USER'].toString(),
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data.containsKey('thread') && data.containsKey('posts')) {
        final posts = data['posts'] as List;

        final fetchedMessages = posts
            .where((post) => post['message_state'] == 'visible')
            .map((post) {
          final user = post['User'];
          final avatarUrl = post['User']['avatar_urls']['s'] ?? '';

          return types.CustomMessage(
            author: types.User(
              id: user['user_id'].toString(),
              firstName: user['username'] ?? 'Unknown',
              imageUrl: avatarUrl,
            ),
            createdAt: post['post_date'] * 1000,
            id: post['post_id'].toString(),
            metadata: {'html': post['message_parsed']},
          );
        }).toList();

        setState(() {
          _messages = fetchedMessages.reversed.toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No discussion to display.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load messages.')),
      );
    }
  }

  Future<void> _addMessage(types.PartialText message) async {
    final box = Hive.box('TTMobileApp');
    final userData = await json.decode(box.get('userData'));

    final customMessage = types.CustomMessage(
      author: types.User(
        id: userData!['user']['user_id'].toString(),
        firstName: userData?['user']['username'],
        imageUrl: userData?['user']['avatar_urls']?['s'],
      ),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().toString(),
      metadata: {'html': message.text},
    );

    setState(() {
      _messages.insert(0, customMessage);
    });

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['FORUM_URL'].toString()}api/posts'),
        headers: {
          'XF-Api-Key': dotenv.env['API_KEY'].toString(),
          'XF-Api-User': userData!['user']['user_id'].toString(),
        },
        body: {
          'thread_id': widget.threadId.toString(),
          'message': message.text,
        },
      );

      if (response.statusCode != 200) {
        _removeMessage(customMessage.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message.')),
        );
      }
    } catch (error) {
      _removeMessage(customMessage.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message.')),
      );
    }
  }

  void _removeMessage(String messageId) {
    setState(() {
      _messages.removeWhere((message) => message.id == messageId);
    });
  }

  Future<void> _blockUser(String userId) async {
    final box = Hive.box('TTMobileApp');

    // Retrieve and decode user data
    final rawData = box.get('userData');
    final userData = json.decode(rawData);

    final response = await http.post(
      Uri.parse('https://www.fl501st.com/boards/mobileapi.php'
          '?action=block_user'
          '&blocker_id=${userData['user']['user_id']}'
          '&blocked_id=$userId'),
      headers: {
        'API-Key': box.get('apiKey') ?? '',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User blocked successfully!')),
      );
    } else {
      print(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to block user!')),
      );
    }
  }

  Future<void> _reportMessage(String messageId) async {
    final box = Hive.box('TTMobileApp');

    // Retrieve and decode user data
    final rawData = box.get('userData');
    final userData = json.decode(rawData);

    // Show a popup to input the report reason
    String? reportReason = await _showInputDialog(context);

    // Check if the user canceled the dialog or entered nothing
    if (reportReason == null || reportReason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report reason cannot be empty!')),
      );
      return; // Stop further execution
    }

    final response = await http.post(
      Uri.parse('https://www.fl501st.com/boards/mobileapi.php'
          '?action=report_post'
          '&reporter_id=${userData['user']['user_id']}'
          '&message=$reportReason'
          '&post_id=$messageId'),
      headers: {
        'API-Key': box.get('apiKey') ?? '',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message reported successfully!')),
      );
    } else {
      print(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to report message!')),
      );
    }
  }

  Future<String?> _getAttachmentKey() async {
    try {
      final box = Hive.box('TTMobileApp');
      final userData = await json.decode(box.get('userData'));

      final response = await http.post(
        Uri.parse(
            '${dotenv.env['FORUM_URL'].toString()}api/attachments/new-key'),
        headers: {
          'XF-Api-Key': dotenv.env['API_KEY'].toString(),
          'XF-Api-User': userData!['user']['user_id'].toString(),
        },
        body: {
          'type': 'post',
          'context[thread_id]': widget.threadId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Attachment Key: ${data['key']}');
        return data['key'];
      } else {
        print('Failed to fetch attachment key: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching attachment key: $e');
      return null;
    }
  }

  // Upload image and add message
  Future<void> _addImageMessage(File imageFile) async {
    try {
      final box = Hive.box('TTMobileApp');
      final userData = await json.decode(box.get('userData'));

      // Fetch attachment key
      final attachmentKey = await _getAttachmentKey();
      if (attachmentKey == null) {
        throw Exception('Failed to retrieve attachment key.');
      }

      // Determine MIME type of the image
      final mimeType = lookupMimeType(imageFile.path);

      // Create a multipart request for XenForo API
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '${dotenv.env['FORUM_URL'].toString()}api/attachments',
        ),
      );

      // Add API headers
      request.headers.addAll({
        'XF-Api-Key': dotenv.env['API_KEY'].toString(),
        'XF-Api-User': userData!['user']['user_id'].toString(),
      });

      // Attach the image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'attachment',
          imageFile.path,
          contentType: MediaType.parse(mimeType!),
        ),
      );

      // Add attachment key
      request.fields['key'] = attachmentKey;

      // Send the request
      final response = await request.send();

      // Read response body
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);

      if (response.statusCode == 200 && data['attachment'] != null) {
        // Get the attachment ID from the response
        final attachmentId = data['attachment']['attachment_id'];

        // Construct the image URL (use thumbnail or full-size view URL)
        final imageUrl = data['attachment']['thumbnail_url'] ??
            data['attachment']['view_url'];

        final msg = types.CustomMessage(
          author: types.User(
            id: userData!['user']['user_id'].toString(),
            firstName: userData?['user']['username'],
            imageUrl: userData?['user']['avatar_urls']?['s'],
          ),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: DateTime.now().toString(),
          metadata: {'html': '<img src=\'$imageUrl\' />'},
        );

        // Add the image message to the chat
        setState(() {
          _messages.insert(0, msg);
        });

        try {
          final responseImagePost = await http.post(
            Uri.parse('${dotenv.env['FORUM_URL'].toString()}api/posts'),
            headers: {
              'XF-Api-Key': dotenv.env['API_KEY'].toString(),
              'XF-Api-User': userData!['user']['user_id'].toString(),
            },
            body: {
              'thread_id': widget.threadId.toString(),
              'message': '[IMG]${data['attachment']['direct_url']}[/IMG]',
              'attachment_key': attachmentKey,
            },
          );

          if (responseImagePost.statusCode != 200) {
            _removeMessage(msg.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to send message.')),
            );
          }
        } catch (error) {
          _removeMessage(msg.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send message.')),
          );
        }
      } else {
        // Show error if upload fails
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image.')),
        );
      }
    } catch (e) {
      // Catch and handle errors
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error uploading image.')),
      );
    }
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    final pickedFile =
        await _picker.pickImage(source: imagePicker.ImageSource.gallery);

    if (pickedFile != null) {
      _addImageMessage(File(pickedFile.path)); // Upload image and send message
    }
  }

  // Capture image using camera
  Future<void> _captureImage() async {
    final pickedFile =
        await _picker.pickImage(source: imagePicker.ImageSource.camera);

    if (pickedFile != null) {
      _addImageMessage(File(pickedFile.path)); // Upload image and send message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Chat with ${widget.troopName}'),
      body: Chat(
        messages: _messages,
        onSendPressed: _addMessage,
        user: user,
        onAttachmentPressed: () {
          // Show options to pick or capture image
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Camera'),
                    onTap: () {
                      Navigator.pop(context);
                      _captureImage();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo),
                    title: const Text('Gallery'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                ],
              );
            },
          );
        },
        customMessageBuilder: (message, {required int messageWidth}) {
          final isSentByUser = message.author.id == user.id;

          if (message.metadata != null &&
              message.metadata!.containsKey('html')) {
            final htmlContent = message.metadata!['html'];

            return GestureDetector(
              onLongPress: () {
                if (!isSentByUser) {
                  // Prevent reporting or blocking yourself
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.block),
                            title: const Text('Block User'),
                            onTap: () {
                              Navigator.pop(context);
                              _blockUser(message.author.id);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.report),
                            title: const Text('Report Message'),
                            onTap: () {
                              Navigator.pop(context);
                              _reportMessage(message.id);
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8.0),
                color: isSentByUser
                    ? Colors.blue[500]
                    : Colors.grey[200], // Custom solid gray
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: isSentByUser
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    if (!isSentByUser)
                      CircleAvatar(
                        backgroundImage: NetworkImage(
                          message.author.imageUrl ??
                              'https://www.fl501st.com/assets/images/profile.png',
                        ),
                        radius: 20,
                      ),
                    if (!isSentByUser) const SizedBox(width: 8.0),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: isSentByUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.author.firstName ?? 'Unknown',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                                color: !isSentByUser
                                    ? Colors.black
                                    : Colors.white),
                          ),
                          const SizedBox(height: 4.0),
                          Container(
                            padding: const EdgeInsets.all(12.0),
                            constraints: BoxConstraints(
                              maxWidth: messageWidth.toDouble(),
                            ),
                            decoration: BoxDecoration(
                              color: isSentByUser
                                  ? Colors.blue[500]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: HtmlWidget(
                              htmlContent,
                              textStyle: TextStyle(
                                color: isSentByUser
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 16.0,
                              ),
                              customWidgetBuilder: (element) {
                                if (element.localName == 'img' &&
                                    element.attributes['src'] != null) {
                                  final imageUrl = element.attributes['src']!;
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Scaffold(
                                            appBar: AppBar(
                                              title: const Text('Image Viewer'),
                                              leading: IconButton(
                                                icon: Icon(Icons.arrow_back),
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                              ),
                                            ),
                                            body: PhotoViewGallery.builder(
                                              itemCount: 1,
                                              builder: (context, index) {
                                                return PhotoViewGalleryPageOptions(
                                                  imageProvider:
                                                      NetworkImage(imageUrl),
                                                  minScale:
                                                      PhotoViewComputedScale
                                                          .contained,
                                                  maxScale:
                                                      PhotoViewComputedScale
                                                              .covered *
                                                          2,
                                                );
                                              },
                                              scrollPhysics:
                                                  const BouncingScrollPhysics(),
                                              backgroundDecoration:
                                                  BoxDecoration(
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Image.network(imageUrl),
                                  );
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSentByUser) const SizedBox(width: 8.0),
                    if (isSentByUser)
                      CircleAvatar(
                        backgroundImage: NetworkImage(
                          message.author.imageUrl ??
                              'https://www.fl501st.com/assets/images/profile.png',
                        ),
                        radius: 20,
                      ),
                    if (isSentByUser) const SizedBox(width: 8.0)
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

Future<String?> _showInputDialog(BuildContext context) async {
  TextEditingController textController = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Report Message'),
      content: TextField(
        controller: textController,
        decoration: const InputDecoration(
          hintText: 'Enter reason for reporting...',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null), // Cancel
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(textController.text), // Submit
          child: const Text('Submit'),
        ),
      ],
    ),
  );
}

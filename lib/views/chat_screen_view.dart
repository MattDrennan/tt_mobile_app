import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../controllers/chat_controller.dart';
import '../models/app_user.dart';
import '../services/api_client.dart';
import '../widgets/tt_app_bar.dart';

class ChatScreenView extends StatefulWidget {
  final String troopName;
  final int threadId;
  final int postId;
  final AppUser currentUser;
  final ApiClient api;

  const ChatScreenView({
    super.key,
    required this.troopName,
    required this.threadId,
    required this.postId,
    required this.currentUser,
    required this.api,
  });

  @override
  State<ChatScreenView> createState() => _ChatScreenViewState();
}

class _ChatScreenViewState extends State<ChatScreenView> {
  late final ChatController _controller;
  final _picker = image_picker.ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = ChatController(
      widget.api,
      currentUser: widget.currentUser,
    );
    _controller.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.openRoom(widget.threadId);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    if (_controller.actionError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.actionError!)),
      );
      _controller.clearActionError();
    }
    setState(() {});
  }

  Future<void> _handleSend(types.PartialText message) async {
    await _controller.sendMessage(message.text);
  }

  Future<void> _pickAndSendImage(image_picker.ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;
    await _controller.sendImageMessage(File(picked.path));
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            onTap: () {
              Navigator.pop(ctx);
              _pickAndSendImage(image_picker.ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text('Gallery'),
            onTap: () {
              Navigator.pop(ctx);
              _pickAndSendImage(image_picker.ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(types.CustomMessage message) {
    final isSelf = message.author.id == widget.currentUser.id;
    if (isSelf) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Block / Unblock User'),
            onTap: () async {
              Navigator.pop(ctx);
              final success = await _controller.blockUser(message.author.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'User block status updated.'
                        : 'Failed to block user.',
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('Report Message'),
            onTap: () async {
              Navigator.pop(ctx);
              final reason = await _showReportDialog(context);
              if (reason == null || reason.trim().isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Report reason cannot be empty!')),
                  );
                }
                return;
              }
              final success =
                  await _controller.reportMessage(message.id, reason);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Message reported successfully!'
                        : 'Failed to report message.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatUser = widget.currentUser.toChatUser();

    return Scaffold(
      appBar: buildAppBar(context, 'Chat with ${widget.troopName}'),
      body: Chat(
        messages: _controller.messages,
        onSendPressed: _handleSend,
        user: chatUser,
        onAttachmentPressed: _showAttachmentSheet,
        customMessageBuilder: (message, {required int messageWidth}) {
          final isSentByUser = message.author.id == chatUser.id;
          final htmlContent = message.metadata?['html']?.toString() ?? '';

          return GestureDetector(
            onLongPress: () => _showMessageOptions(message),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              color: isSentByUser ? Colors.blue[500] : Colors.grey[200],
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: isSentByUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  if (!isSentByUser) ...[
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                        message.author.imageUrl ??
                            'https://www.fl501st.com/assets/images/profile.png',
                      ),
                      radius: 20,
                    ),
                    const SizedBox(width: 8.0),
                  ],
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
                            color: isSentByUser ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          constraints:
                              BoxConstraints(maxWidth: messageWidth.toDouble()),
                          decoration: BoxDecoration(
                            color: isSentByUser
                                ? Colors.blue[500]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: HtmlWidget(
                            htmlContent,
                            textStyle: TextStyle(
                              color:
                                  isSentByUser ? Colors.white : Colors.black87,
                              fontSize: 16.0,
                            ),
                            customWidgetBuilder: (element) {
                              if (element.localName == 'img' &&
                                  element.attributes['src'] != null) {
                                final imageUrl = element.attributes['src']!;
                                return GestureDetector(
                                  onTap: () =>
                                      _openImageViewer(context, imageUrl),
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
                  if (isSentByUser) ...[
                    const SizedBox(width: 8.0),
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                        message.author.imageUrl ??
                            'https://www.fl501st.com/assets/images/profile.png',
                      ),
                      radius: 20,
                    ),
                    const SizedBox(width: 8.0),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openImageViewer(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Image Viewer'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: PhotoViewGallery.builder(
            itemCount: 1,
            builder: (_, __) => PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            ),
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }
}

Future<String?> _showReportDialog(BuildContext context) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Report Message'),
      content: TextField(
        controller: controller,
        decoration:
            const InputDecoration(hintText: 'Enter reason for reporting...'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(controller.text),
          child: const Text('Submit'),
        ),
      ],
    ),
  );
}

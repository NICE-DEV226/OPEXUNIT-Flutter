import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

/// Conversation client avec le Centre de Commandement (messagerie).
/// Conforme à la maquette : header (avatar, titre, En ligne, appel vidéo), bulles Admin / utilisateur, pièce jointe, champ d'envoi.
class ClientCommandCenterChatScreen extends StatefulWidget {
  const ClientCommandCenterChatScreen({super.key});

  @override
  State<ClientCommandCenterChatScreen> createState() => _ClientCommandCenterChatScreenState();
}

class _ClientCommandCenterChatScreenState extends State<ClientCommandCenterChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      isFromMe: false,
      senderLabel: AppStrings.adminLabel,
      text: 'Signalement confirmé. Position :',
      time: '09:42',
      isImageAttachment: false,
    ),
    _ChatMessage(
      isFromMe: true,
      text: 'Je suis devant l\'entrée Nord. Aucun mouvement suspect.',
      time: '09:43',
      isImageAttachment: false,
    ),
    _ChatMessage(
      isFromMe: false,
      senderLabel: AppStrings.adminLabel,
      text: 'Bien reçu. Restez en stand-by.',
      time: '09:44',
      isImageAttachment: false,
    ),
    _ChatMessage(
      isFromMe: true,
      text: 'Image_Entree_Nord.jpg',
      time: '09:45',
      isImageAttachment: true,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryRed),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryRed.withValues(alpha: 0.15),
              child: Icon(Icons.shield_rounded, color: AppColors.primaryRed, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.commandCenter,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.online,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF22C55E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.videocam_rounded, color: AppColors.primaryRed, size: 26),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.videoCallStub),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _buildDateSeparator(),
                ..._messages.map((m) => _ChatBubble(message: m)),
              ],
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildDateSeparator() {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: Text(
          '${AppStrings.today} $timeStr',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file_rounded, color: Color(0xFF6B7280), size: 24),
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryRed),
                            title: Text(AppStrings.photoGallery),
                            onTap: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppStrings.sendPhotoStub), duration: const Duration(seconds: 2)),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.insert_drive_file_outlined, color: AppColors.primaryRed),
                            title: Text(AppStrings.file),
                            onTap: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppStrings.sendFileStub), duration: const Duration(seconds: 2)),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: AppStrings.writeMessage,
                          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                        maxLines: null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.mic_none_rounded, color: Color(0xFF6B7280), size: 22),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppStrings.voiceNoteOptional),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.primaryRed,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: () {
                  final text = _controller.text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppStrings.sendMessageStub), duration: const Duration(seconds: 2)),
                    );
                    return;
                  }
                  setState(() {
                    _messages.add(_ChatMessage(isFromMe: true, text: text, time: _formatTime(DateTime.now()), isImageAttachment: false));
                    _controller.clear();
                  });
                  Future.microtask(() {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    }
                  });
                },
                borderRadius: BorderRadius.circular(24),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _ChatMessage {
  final bool isFromMe;
  final String? senderLabel;
  final String text;
  final String time;
  final bool isImageAttachment;

  _ChatMessage({
    required this.isFromMe,
    this.senderLabel,
    required this.text,
    required this.time,
    this.isImageAttachment = false,
  });
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!message.isFromMe) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFE5E7EB),
                child: Icon(Icons.person_rounded, size: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: message.isFromMe ? AppColors.primaryRed : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(message.isFromMe ? 16 : 4),
                    bottomRight: Radius.circular(message.isFromMe ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.senderLabel != null && !message.isFromMe)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${message.senderLabel} • ${message.time}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (message.isImageAttachment) ...[
                          Icon(
                            Icons.image_outlined,
                            size: 20,
                            color: message.isFromMe ? Colors.white70 : const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            message.text,
                            style: TextStyle(
                              fontSize: 14,
                              color: message.isFromMe ? Colors.white : const Color(0xFF111827),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (message.isFromMe || message.senderLabel == null) ...[
                      const SizedBox(height: 4),
                      Text(
                        message.time,
                        style: TextStyle(
                          fontSize: 11,
                          color: message.isFromMe ? Colors.white70 : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (message.isFromMe) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

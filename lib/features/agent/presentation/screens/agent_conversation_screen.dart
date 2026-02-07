import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class AgentConversationScreen extends StatelessWidget {
  final String threadId;
  final String threadName;

  const AgentConversationScreen({
    super.key,
    required this.threadId,
    required this.threadName,
  });

  /// Messages mockés par conversation (à remplacer par une vraie source plus tard).
  static List<_ChatMessage> _messagesFor(String id) {
    switch (id) {
      case '1':
        return [
          _ChatMessage(isFromMe: false, text: AppStrings.patrolValidatedSiteA, time: '10:44'),
          _ChatMessage(isFromMe: true, text: AppStrings.thanksRoundOnTime, time: '10:45'),
          _ChatMessage(isFromMe: false, text: AppStrings.perfectSeeYou, time: '10:45'),
        ];
      case '2':
        return [
          _ChatMessage(isFromMe: false, text: AppStrings.reminderNextRound, time: AppStrings.yesterday),
          _ChatMessage(isFromMe: true, text: AppStrings.notedIllBeThere, time: AppStrings.yesterday),
        ];
      case '3':
        return [
          _ChatMessage(isFromMe: true, text: AppStrings.reportDoneZoneB, time: AppStrings.mondayShort),
          _ChatMessage(isFromMe: false, text: AppStrings.thanksForReport, time: AppStrings.mondayShort),
        ];
      default:
        return [
          _ChatMessage(isFromMe: false, text: AppStrings.noMessageInConversation, time: ''),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = _messagesFor(threadId);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          threadName,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.call_rounded, color: AppColors.primaryRed),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.voiceCallStub),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: AppColors.primaryRed),
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
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _ChatBubble(message: messages[index]);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + MediaQuery.of(context).padding.bottom,
            ),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded, color: Color(0xFF6B7280)),
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
                                      SnackBar(
                                        content: Text(AppStrings.sendPhotoStub),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.insert_drive_file_outlined, color: AppColors.primaryRed),
                                  title: Text(AppStrings.file),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(AppStrings.sendFileStub),
                                        duration: const Duration(seconds: 2),
                                      ),
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
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: AppStrings.writeMessage,
                          hintStyle: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                        maxLines: null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppStrings.sendMessageStub),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final bool isFromMe;
  final String text;
  final String time;

  _ChatMessage({
    required this.isFromMe,
    required this.text,
    required this.time,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
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
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                color: message.isFromMe ? Colors.white : const Color(0xFF111827),
                height: 1.35,
              ),
            ),
            if (message.time.isNotEmpty) ...[
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
    );
  }
}

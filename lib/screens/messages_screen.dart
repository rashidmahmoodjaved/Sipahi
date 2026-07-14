import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthService>().user!;

    return StreamBuilder<QuerySnapshot>(
      stream: context.read<ChatService>().getChatList(currentUser.uid),
      builder: (context, chatSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: context.read<ChatService>().getGroupList(currentUser.uid),
          builder: (context, groupSnapshot) {
            if (chatSnapshot.connectionState == ConnectionState.waiting ||
                groupSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            List<Widget> tiles = [];

            // Individual chats
            if (chatSnapshot.hasData) {
              for (var doc in chatSnapshot.data!.docs) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                tiles.add(
                  _buildChatTile(
                    data,
                    currentUser.uid,
                    context,
                    isGroup: false,
                  ),
                );
              }
            }

            // Group chats
            if (groupSnapshot.hasData) {
              for (var doc in groupSnapshot.data!.docs) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                tiles.add(
                  _buildChatTile(
                    data,
                    currentUser.uid,
                    context,
                    isGroup: true,
                  ),
                );
              }
            }

            if (tiles.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.message, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No messages yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView(children: tiles);
          },
        );
      },
    );
  }

  Widget _buildChatTile(
    Map<String, dynamic> data,
    String currentUserId,
    BuildContext context, {
    required bool isGroup,
  }) {
    String title = isGroup ? (data['groupName'] ?? 'Group') : 'User';

    String lastMessage = data['lastMessage'] ?? 'No messages';
    DateTime? lastTime;

    if (data['lastMessageTime'] != null) {
      lastTime = (data['lastMessageTime'] as Timestamp).toDate();
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.indigo.shade100,
        child: Icon(
          isGroup ? Icons.group : Icons.person,
          color: Colors.indigo,
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: lastTime != null
          ? Text(
              DateFormat('HH:mm').format(lastTime),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            )
          : null,
      onTap: () {
        if (isGroup) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                userId: currentUserId,
                userName: '',
                groupId: data['groupId'],
                groupName: data['groupName'],
              ),
            ),
          );
        } else {
          List<String> participants = List<String>.from(data['participants']);
          String otherUserId = participants.firstWhere(
            (id) => id != currentUserId,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                userId: otherUserId,
                userName: title,
              ),
            ),
          );
        }
      },
    );
  }
}

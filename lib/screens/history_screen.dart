import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:todo_advance/services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

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

            List<Widget> items = [];

            // Add individual chats
            if (chatSnapshot.hasData) {
              for (var doc in chatSnapshot.data!.docs) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                items.add(
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(data['lastMessage'] ?? 'No messages'),
                    subtitle: Text(doc.id),
                    trailing: Text(
                      DateFormat('HH:mm').format(
                        (data['lastMessageTime'] as Timestamp).toDate(),
                      ),
                    ),
                    onTap: () {
                      List<String> participants =
                          List<String>.from(data['participants']);
                      String otherUserId = participants.firstWhere(
                        (id) => id != currentUser.uid,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            userId: otherUserId,
                            userName: 'User',
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
            }

            // Add group chats
            if (groupSnapshot.hasData) {
              for (var doc in groupSnapshot.data!.docs) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                items.add(
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.group),
                    ),
                    title: Text(data['groupName'] ?? 'Group'),
                    subtitle: Text(data['lastMessage'] ?? 'No messages'),
                    trailing: Text(
                      DateFormat('HH:mm').format(
                        (data['lastMessageTime'] as Timestamp).toDate(),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            userId: currentUser.uid,
                            userName: '',
                            groupId: data['groupId'],
                            groupName: data['groupName'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
            }

            if (items.isEmpty) {
              return const Center(
                child: Text('No chat history'),
              );
            }

            return ListView(
              children: items,
            );
          },
        );
      },
    );
  }
}

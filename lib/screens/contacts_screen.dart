import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_advance/model/user_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() {
    final currentUserId = context.read<AuthService>().user!.uid;
    context.read<ChatService>().loadContacts(currentUserId);
  }

  Future<void> _addContact() async {
    String email = _emailController.text.trim();
    if (email.isNotEmpty) {
      final currentUserId = context.read<AuthService>().user!.uid;
      await context.read<ChatService>().addContact(email, currentUserId);
      _emailController.clear();
      Navigator.pop(context);
    }
  }

  void _showAddContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Contact'),
        content: TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            hintText: 'Enter email address',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _addContact,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateGroupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatService>(
      builder: (context, chatService, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _showAddContactDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Contact'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showCreateGroupDialog,
                    icon: const Icon(Icons.group_add),
                    label: const Text('Create Group'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: chatService.contacts.isEmpty
                  ? const Center(
                      child: Text('No contacts yet'),
                    )
                  : ListView.builder(
                      itemCount: chatService.contacts.length,
                      itemBuilder: (context, index) {
                        UserModel contact = chatService.contacts[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.shade100,
                            child: Text(
                              contact.displayName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.indigo,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(contact.displayName),
                          subtitle: Text(contact.email),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.red,
                            onPressed: () {
                              chatService.removeContact(
                                contact.uid,
                                context.read<AuthService>().user!.uid,
                              );
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  userId: contact.uid,
                                  userName: contact.displayName,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _groupNameController = TextEditingController();
  final Set<String> _selectedMembers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        actions: [
          TextButton(
            onPressed: _createGroup,
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Members',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<ChatService>(
              builder: (context, chatService, _) {
                return ListView.builder(
                  itemCount: chatService.contacts.length,
                  itemBuilder: (context, index) {
                    UserModel contact = chatService.contacts[index];
                    bool isSelected = _selectedMembers.contains(contact.uid);

                    return CheckboxListTile(
                      title: Text(contact.displayName),
                      subtitle: Text(contact.email),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedMembers.add(contact.uid);
                          } else {
                            _selectedMembers.remove(contact.uid);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _createGroup() async {
    if (_groupNameController.text.trim().isNotEmpty &&
        _selectedMembers.isNotEmpty) {
      await context.read<ChatService>().createGroup(
            groupName: _groupNameController.text.trim(),
            creatorId: context.read<AuthService>().user!.uid,
            memberIds: _selectedMembers.toList(),
          );

      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter group name and select members'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }
}

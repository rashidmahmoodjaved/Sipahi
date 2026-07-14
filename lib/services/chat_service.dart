import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../model/user_model.dart';
import '../models/message_model.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  List<UserModel> _contacts = [];
  final List<MessageModel> _messages = [];
  final Map<String, List<MessageModel>> _chatHistory = {};

  List<UserModel> get contacts => _contacts;
  List<MessageModel> get messages => _messages;
  Map<String, List<MessageModel>> get chatHistory => _chatHistory;

  Future<void> loadContacts(String currentUserId) async {
    QuerySnapshot snapshot = await _firestore.collection('users').get();
    _contacts = snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
        .where((user) => user.uid != currentUserId)
        .toList();
    notifyListeners();
  }

  Future<void> addContact(String email, String currentUserId) async {
    QuerySnapshot query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (query.docs.isNotEmpty) {
      UserModel contact = UserModel.fromMap(
        query.docs.first.data() as Map<String, dynamic>,
      );

      if (!_contacts.any((c) => c.uid == contact.uid)) {
        await _firestore
            .collection('contacts')
            .doc(currentUserId)
            .collection('userContacts')
            .doc(contact.uid)
            .set({'addedAt': FieldValue.serverTimestamp()});

        _contacts.add(contact);
        notifyListeners();
      }
    }
  }

  Future<void> removeContact(String contactId, String currentUserId) async {
    await _firestore
        .collection('contacts')
        .doc(currentUserId)
        .collection('userContacts')
        .doc(contactId)
        .delete();

    _contacts.removeWhere((contact) => contact.uid == contactId);
    notifyListeners();
  }

  Stream<List<MessageModel>> getMessages({
    required String userId,
    required String otherUserId,
    String? groupId,
  }) {
    String chatId = _getChatId(userId, otherUserId);

    Query query;
    if (groupId != null) {
      query = _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .orderBy('timestamp', descending: true);
    } else {
      query = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => MessageModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }

  Future<void> sendTextMessage({
    required String senderId,
    required String receiverId,
    required String text,
    String? groupId,
  }) async {
    String chatId = _getChatId(senderId, receiverId);
    String messageId = const Uuid().v4();

    MessageModel message = MessageModel(
      id: messageId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      type: MessageType.text,
      timestamp: DateTime.now(),
      groupId: groupId,
    );

    String collectionPath;
    if (groupId != null) {
      collectionPath = 'groups/$groupId/messages';
    } else {
      collectionPath = 'chats/$chatId/messages';
    }

    await _firestore
        .collection(collectionPath)
        .doc(messageId)
        .set(message.toMap());

    await _updateLastMessage(senderId, receiverId, text, groupId);
  }

  Future<void> sendImageMessage({
    required String senderId,
    required String receiverId,
    required XFile image,
    String? groupId,
  }) async {
    String chatId = _getChatId(senderId, receiverId);
    String messageId = const Uuid().v4();

    String fileName =
        'chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference ref = _storage.ref().child(fileName);
    await ref.putFile(await image.readAsBytes() as dynamic);
    String imageUrl = await ref.getDownloadURL();

    MessageModel message = MessageModel(
      id: messageId,
      senderId: senderId,
      receiverId: receiverId,
      imageUrl: imageUrl,
      type: MessageType.image,
      timestamp: DateTime.now(),
      groupId: groupId,
    );

    String collectionPath = groupId != null
        ? 'groups/$groupId/messages'
        : 'chats/$chatId/messages';

    await _firestore
        .collection(collectionPath)
        .doc(messageId)
        .set(message.toMap());

    await _updateLastMessage(senderId, receiverId, '📷 Image', groupId);
  }

  Future<void> sendLocationMessage({
    required String senderId,
    required String receiverId,
    String? groupId,
  }) async {
    String chatId = _getChatId(senderId, receiverId);
    String messageId = const Uuid().v4();

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final Geocoding geocoding = Geocoding();
    List<Placemark> placemarks = await geocoding.placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    String locationName = placemarks.isNotEmpty
        ? '${placemarks.first.street}, ${placemarks.first.locality}'
        : 'Shared Location';

    MessageModel message = MessageModel(
      id: messageId,
      senderId: senderId,
      receiverId: receiverId,
      latitude: position.latitude,
      longitude: position.longitude,
      locationName: locationName,
      type: MessageType.location,
      timestamp: DateTime.now(),
      groupId: groupId,
    );

    String collectionPath = groupId != null
        ? 'groups/$groupId/messages'
        : 'chats/$chatId/messages';

    await _firestore
        .collection(collectionPath)
        .doc(messageId)
        .set(message.toMap());

    await _updateLastMessage(senderId, receiverId, '📍 Location', groupId);
  }

  Future<void> createGroup({
    required String groupName,
    required String creatorId,
    required List<String> memberIds,
  }) async {
    String groupId = const Uuid().v4();

    await _firestore.collection('groups').doc(groupId).set({
      'groupId': groupId,
      'groupName': groupName,
      'creatorId': creatorId,
      'members': [creatorId, ...memberIds],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': 'Group created',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    notifyListeners();
  }

  String _getChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }

  Future<void> _updateLastMessage(
    String senderId,
    String receiverId,
    String message,
    String? groupId,
  ) async {
    if (groupId != null) {
      await _firestore.collection('groups').doc(groupId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } else {
      String chatId = _getChatId(senderId, receiverId);
      await _firestore.collection('chats').doc(chatId).set({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'participants': [senderId, receiverId],
      }, SetOptions(merge: true));
    }
  }

  Stream<QuerySnapshot> getChatList(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getGroupList(String userId) {
    return _firestore
        .collection('groups')
        .where('members', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }
}

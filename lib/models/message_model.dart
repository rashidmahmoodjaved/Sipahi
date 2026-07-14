import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String? text;
  final String? imageUrl;
  final String? audioUrl;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? groupId;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.text,
    this.imageUrl,
    this.audioUrl,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.groupId,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'],
      imageUrl: map['imageUrl'],
      audioUrl: map['audioUrl'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      locationName: map['locationName'],
      type: MessageType.values[map['type'] ?? 0],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      groupId: map['groupId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'type': type.index,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'groupId': groupId,
    };
  }
}

enum MessageType {
  text,
  image,
  audio,
  location,
  groupCreate,
  groupJoin,
  groupLeave,
}

import 'package:hive/hive.dart';

part 'conversation.g.dart';

@HiveType(typeId: 1)
class ChatMessage extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final String question;

  @HiveField(3)
  final String answer;

  /// 'gemma4', 'knowledge_base', or 'cached'
  @HiveField(4)
  final String source;

  /// Optional scan context — e.g. "phytophthora (87% confidence)"
  /// Stored so the chat history shows what disease context was used.
  @HiveField(5)
  final String? scanContext;

  ChatMessage({
    required this.id,
    required this.timestamp,
    required this.question,
    required this.answer,
    required this.source,
    this.scanContext,
  });
}

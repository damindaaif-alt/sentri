import 'package:equatable/equatable.dart';

class BlockedNumber extends Equatable {
  final int id;
  final String phoneNumber;
  final String? label;
  final bool isPermanent;
  final DateTime blockedAt;

  const BlockedNumber({
    required this.id,
    required this.phoneNumber,
    this.label,
    required this.isPermanent,
    required this.blockedAt,
  });

  @override
  List<Object?> get props => [id, phoneNumber, label, isPermanent, blockedAt];
}

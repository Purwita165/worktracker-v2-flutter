 import 'package:flutter/material.dart';

 
 String formatSeq(String? input) {
    if (input == null || input.isEmpty) return '-';

    final parts = input.split('.');

    return parts
        .map((part) {
          final num = int.tryParse(part);
          return num != null ? num.toString().padLeft(3, '0') : part;
        })
        .join('.');
  }

  Color getScheduleColor(
  DateTime? startDate,
  DateTime? dueDate,
  DateTime? startedAt,
) {
  final now = DateTime.now();

  // 🔴 PRIORITAS 1: overdue (paling penting)
  if (dueDate != null && now.isAfter(dueDate)) {
    return Colors.red;
  }

  // kalau belum ada startDate
  if (startDate == null) return Colors.grey;

  final diff = startDate.difference(now).inDays;

  // jauh dari start
  if (diff > 7) return Colors.grey;

  // H-7 sampai H-3
  if (diff <= 7 && diff > 2) return Colors.green;

  // H-2 sampai H
  if (diff <= 2 && diff >= 0) return Colors.yellow;

  // sudah lewat start tapi belum mulai
  if (diff < 0 && startedAt == null) return Colors.orange;

  return Colors.grey;
}

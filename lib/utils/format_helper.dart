 import 'package:flutter/material.dart';

 
 int compareSeq(String a, String b) {
  List<dynamic> parse(String input) {
    final parts = input.split('.');
    return parts.map((part) {
      final isMilestone = part.endsWith('M');
      final numberPart = part.replaceAll('M', '');
      final num = int.tryParse(numberPart) ?? 0;
      return {
        'num': num,
        'isMilestone': isMilestone,
      };
    }).toList();
  }

  final aParts = parse(a);
  final bParts = parse(b);

  final maxLength = aParts.length > bParts.length ? aParts.length : bParts.length;

  for (int i = 0; i < maxLength; i++) {
    final aVal = i < aParts.length ? aParts[i] : {'num': 0, 'isMilestone': false};
    final bVal = i < bParts.length ? bParts[i] : {'num': 0, 'isMilestone': false};

    if (aVal['num'] != bVal['num']) {
      return aVal['num'].compareTo(bVal['num']);
    }

    // angka sama → milestone ditaruh setelah task
    if (aVal['isMilestone'] != bVal['isMilestone']) {
      return aVal['isMilestone'] ? 1 : -1;
    }
  }

  return 0;
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

String formatSeq(String? input) {
  if (input == null || input.isEmpty) return '-';

  final parts = input.split('.');

  return parts.map((part) {
    final isMilestone = part.toUpperCase().endsWith('M');

    // ambil angka saja
    final numberPart = part.replaceAll(RegExp(r'[^0-9]'), '');
    final num = int.tryParse(numberPart) ?? 0;

    // hasilkan kembali
    return isMilestone ? '${num}M' : num.toString();
  }).join('.');
}

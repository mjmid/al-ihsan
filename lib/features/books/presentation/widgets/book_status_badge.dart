import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/book_model.dart';
import '../../../../core/l10n/app_translations.dart';

class BookStatusBadge extends ConsumerWidget {
  final BookStatus status;

  const BookStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationProvider);
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case BookStatus.available:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        label = t.bookStatusAvailable;
        break;
      case BookStatus.lent:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        label = t.bookStatusIssued;
        break;
      case BookStatus.lost:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        label = t.bookStatusLost;
        break;
      case BookStatus.damaged:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        label = t.bookDamagedStatus;
        break;
      case BookStatus.referenceOnly:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        label = t.bookReferenceStatus;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

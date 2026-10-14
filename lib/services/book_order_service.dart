import '../models/book.dart';

class BookOrderService {
  static String _normalizeComparable(String? value) =>
      (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static int nextOrderForBooks(Iterable<Book> books) {
    if (books.isEmpty) return 1;
    final maxOrder = books
        .map((book) => book.order)
        .reduce((currentMax, order) => order > currentMax ? order : currentMax);
    return maxOrder + 1;
  }

  static List<Book> reindexBooksInGroup(List<Book> books) {
    final sorted = [...books]
      ..sort((a, b) {
        final orderCompare = a.order.compareTo(b.order);
        if (orderCompare != 0) return orderCompare;
        return _normalizeComparable(
          a.title,
        ).compareTo(_normalizeComparable(b.title));
      });

    final reindexed = <Book>[];
    for (var i = 0; i < sorted.length; i++) {
      reindexed.add(sorted[i].copyWith(order: i + 1));
    }
    return reindexed;
  }

  static List<Book> insertBookAtOrder(
    List<Book> books,
    Book book, {
    required int requestedOrder,
  }) {
    final safeOrder = requestedOrder < 1 ? 1 : requestedOrder;
    final updatedBooks = books.where((item) => item.id != book.id).toList();
    final insertIndex = safeOrder > updatedBooks.length
        ? updatedBooks.length
        : safeOrder - 1;
    final shifted = <Book>[];

    for (var i = 0; i < updatedBooks.length; i++) {
      final current = updatedBooks[i];
      if (i >= insertIndex) {
        shifted.add(current.copyWith(order: current.order + 1));
      } else {
        shifted.add(current.copyWith(order: current.order));
      }
    }

    shifted.insert(insertIndex, book.copyWith(order: safeOrder));
    return reindexBooksInGroup(shifted);
  }
}

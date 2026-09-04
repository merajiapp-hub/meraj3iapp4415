import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book.dart';
import 'statistics_provider.dart';
import 'package:provider/provider.dart';
import '../services/admin_activity_service.dart';

class FavoritesProvider extends ChangeNotifier {
  static const String _favoritesKey = 'favorite_books_v2';
  final List<Book> _favoriteBooks = [];

  List<Book> get favoriteBooks => _favoriteBooks;

  FavoritesProvider() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString(_favoritesKey);

    if (favoritesJson != null && favoritesJson.isNotEmpty) {
      try {
        final List<dynamic> decodedList = json.decode(favoritesJson);
        _favoriteBooks.clear();
        for (var item in decodedList) {
          _favoriteBooks.add(Book.fromMap(item, item['id'] ?? ''));
        }
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading favorites: $e');
      }
    }
  }

  Future<void> toggleFavorite(BuildContext context, Book book) async {
    final bool isExist = _favoriteBooks.any(
      (b) => b.uniqueKey == book.uniqueKey,
    );
    
    final stats = Provider.of<StatisticsProvider>(context, listen: false);
    final isUploaded = book.section == 'uploaded';
    final user = FirebaseAuth.instance.currentUser;

    if (isExist) {
      _favoriteBooks.removeWhere((b) => b.uniqueKey == book.uniqueKey);
      stats.decrementBookStat(
        book.uniqueKey, 
        'favoriteCount', 
        isUploaded: isUploaded, 
        docId: isUploaded ? book.id : null,
      );
      stats.decrementUserStat('favoriteBooks');
      
      if (user != null) {
        AdminActivityService.log(
          type: AdminActivityType.bookUnfavorited,
          title: 'إزالة كتاب من المفضلة',
          description: 'قام المستخدم ${user.email ?? user.uid} بإزالة الكتاب: "${book.title}" من مفضلته',
          targetUserId: user.uid,
          metadata: {'bookId': book.id, 'bookTitle': book.title},
        ).catchError((_) {});
      }
    } else {
      _favoriteBooks.add(book);
      stats.incrementBookStat(
        book.uniqueKey, 
        'favoriteCount', 
        isUploaded: isUploaded, 
        docId: isUploaded ? book.id : null,
      );
      stats.incrementUserStat('favoriteBooks');
      
      if (user != null) {
        AdminActivityService.log(
          type: AdminActivityType.bookFavorited,
          title: 'إضافة كتاب للمفضلة',
          description: 'قام المستخدم ${user.email ?? user.uid} بإضافة الكتاب: "${book.title}" إلى مفضلته',
          targetUserId: user.uid,
          metadata: {'bookId': book.id, 'bookTitle': book.title},
        ).catchError((_) {});
      }
    }

    notifyListeners();
    await _saveFavorites();
  }

  bool isFavorite(String uniqueKey) {
    return _favoriteBooks.any((b) => b.uniqueKey == uniqueKey);
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> mappedList = _favoriteBooks
        .map((b) => b.toMap())
        .toList();
    final String jsonString = json.encode(mappedList);
    await prefs.setString(_favoritesKey, jsonString);
  }

  void clearAll() {
    _favoriteBooks.clear();
    notifyListeners();
  }
}

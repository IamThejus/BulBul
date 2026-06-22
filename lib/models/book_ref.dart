import 'package:equatable/equatable.dart';

import 'book.dart';
import 'favorite_book.dart';

/// A minimal, navigation-friendly reference to a book. We pass this as router
/// `extra` so the Details screen can render its header (title/author/cover)
/// *instantly* while the full work record loads — and so it has everything it
/// needs to favorite or open the reader without another fetch.
///
/// It's the common denominator between a search [Book] and a stored
/// [FavoriteBook], which is why both Search and Favorites can navigate the same
/// route.
class BookRef extends Equatable {
  const BookRef({
    required this.workId,
    required this.title,
    required this.author,
    this.coverUrl,
    this.firstPublishYear,
    this.pageCount,
    this.iaIdentifiers = const [],
  });

  final String workId;
  final String title;
  final String author;
  final String? coverUrl;
  final int? firstPublishYear;
  final int? pageCount;
  final List<String> iaIdentifiers;

  factory BookRef.fromBook(Book b) => BookRef(
        workId: b.workId,
        title: b.title,
        author: b.authorLabel,
        coverUrl: b.coverUrl,
        firstPublishYear: b.firstPublishYear,
        pageCount: b.medianPages,
        iaIdentifiers: b.iaIdentifiers,
      );

  factory BookRef.fromFavorite(FavoriteBook f) => BookRef(
        workId: f.workId,
        title: f.title,
        author: f.author,
        coverUrl: f.coverUrl,
        firstPublishYear: f.firstPublishYear,
        iaIdentifiers: f.iaIdentifier != null ? [f.iaIdentifier!] : const [],
      );

  FavoriteBook toFavorite() => FavoriteBook(
        workId: workId,
        title: title,
        author: author,
        coverUrl: coverUrl,
        firstPublishYear: firstPublishYear,
        iaIdentifier: iaIdentifiers.isNotEmpty ? iaIdentifiers.first : null,
      );

  @override
  List<Object?> get props => [workId, title, author, coverUrl];
}

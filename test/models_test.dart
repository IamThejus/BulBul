import 'package:bulbul/models/archive_item.dart';
import 'package:bulbul/models/book.dart';
import 'package:bulbul/models/book_details.dart';
import 'package:bulbul/models/gutenberg_book.dart';
import 'package:bulbul/models/reading_progress.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure unit tests for the data layer — these validate the generated JSON
/// (de)serialization and the polymorphic-field normalizers without needing a
/// Flutter binding or Hive, so they run fast and deterministically.
void main() {
  group('Book.fromJson', () {
    test('parses an Open Library search doc and derives helpers', () {
      final book = Book.fromJson({
        'key': '/works/OL45804W',
        'title': 'Fantastic Mr Fox',
        'author_name': ['Roald Dahl'],
        'cover_i': 6498519,
        'first_publish_year': 1970,
        'ia': ['fantasticmrfox0000dahl'],
      });

      expect(book.workId, 'OL45804W'); // `/works/` prefix stripped
      expect(book.authorLabel, 'Roald Dahl');
      expect(book.hasInternetArchive, isTrue);
      expect(book.coverUrl, contains('6498519-L.jpg'));
    });

    test('falls back gracefully when optional fields are missing', () {
      final book = Book.fromJson({'key': 'OL1W', 'title': 'Untitled'});
      expect(book.authors, isEmpty);
      expect(book.authorLabel, 'Unknown author');
      expect(book.coverUrl, isNull);
      expect(book.hasInternetArchive, isFalse);
    });
  });

  group('BookDetails.fromJson', () {
    test('normalizes a typed-text description object', () {
      final d = BookDetails.fromJson({
        'key': '/works/OL1W',
        'title': 'A Book',
        'description': {'type': '/type/text', 'value': 'Hello'},
        'covers': [-1, 42],
      });
      expect(d.description, 'Hello');
      expect(d.primaryCoverId, 42); // -1 sentinel skipped
    });

    test('accepts a plain-string description', () {
      final d = BookDetails.fromJson({
        'key': '/works/OL1W',
        'title': 'A Book',
        'description': 'Plain',
      });
      expect(d.description, 'Plain');
    });
  });

  group('GutenbergBook.fromJson', () {
    test('extracts EPUB/HTML download URLs from the formats map', () {
      final g = GutenbergBook.fromJson({
        'id': 1342,
        'title': 'Pride and Prejudice',
        'authors': [
          {'name': 'Austen, Jane', 'birth_year': 1775, 'death_year': 1817}
        ],
        'formats': {
          'application/epub+zip': 'https://gutenberg.org/1342.epub',
          'text/html': 'https://gutenberg.org/1342.html',
        },
      });
      expect(g.epubUrl, endsWith('.epub'));
      expect(g.htmlUrl, endsWith('.html'));
      expect(g.isReadable, isTrue);
      expect(g.authorLabel, 'Austen, Jane');
    });
  });

  group('ArchiveItem.fromJson', () {
    test('normalizes a string creator into a list', () {
      final a = ArchiveItem.fromJson({
        'identifier': 'somebook',
        'title': 'Some Book',
        'creator': 'A. Writer',
        'year': 1901,
      });
      expect(a.creators, ['A. Writer']);
      expect(a.year, '1901'); // int coerced to string
      expect(a.thumbnailUrl, contains('somebook'));
    });
  });

  group('ReadingProgress', () {
    test('computes a whole-number percent label and finished state', () {
      final p = ReadingProgress(
        id: 'OL1W',
        title: 'T',
        author: 'A',
        format: 'epub',
        contentUrl: 'x',
        percent: 0.426,
      );
      expect(p.percentLabel, 43);
      expect(p.isStarted, isTrue);
      expect(p.isFinished, isFalse);
      expect(p.copyWith(percent: 1.0).isFinished, isTrue);
    });
  });
}

import 'package:flutter/material.dart';
import 'book_model.dart';
import 'reader_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _searchQuery = '';
  bool _showOnlyBookmarked = false;

  List<Book> get _filteredBooks {
    return MockLibrary.books.where((book) {
      final matchesSearch = book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.author.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesBookmark = !_showOnlyBookmarked || book.isBookmarked;
      return matchesSearch && matchesBookmark;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final recentBooks = MockLibrary.books.where((b) => b.lastPage > 0).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('My Library', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: Icon(_showOnlyBookmarked ? Icons.bookmark : Icons.bookmark_border),
                onPressed: () => setState(() => _showOnlyBookmarked = !_showOnlyBookmarked),
              ),
            ],
          ),
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by title or author...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ),
          
          if (recentBooks.isNotEmpty && _searchQuery.isEmpty && !_showOnlyBookmarked) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('Continue Reading', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: recentBooks.length,
                  itemBuilder: (context, index) {
                    final book = recentBooks[index];
                    return _buildRecentCard(context, book);
                  },
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text('All Books', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),

          if (_filteredBooks.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.library_books, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No books found', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.6,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final book = _filteredBooks[index];
                    return _buildBookCard(context, book);
                  },
                  childCount: _filteredBooks.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildRecentCard(BuildContext context, Book book) {
    return GestureDetector(
      onTap: () => _openBook(context, book),
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(book.coverUrl, width: 80, height: 120, fit: BoxFit.cover),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title, 
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text(book.author, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const Spacer(),
                  const Text('Last read: 2 hours ago', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: 0.4, // Mock progress
                      backgroundColor: Colors.grey.shade200,
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCard(BuildContext context, Book book) {
    return GestureDetector(
      onTap: () => _openBook(context, book),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    image: DecorationImage(
                      image: NetworkImage(book.coverUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (book.isBookmarked)
                  const Positioned(
                    top: 8, right: 8,
                    child: Icon(Icons.bookmark, color: Colors.amber, size: 28),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            book.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            book.author,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _openBook(BuildContext context, Book book) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReaderScreen(book: book)),
    );
    setState(() {}); // Refresh to show progress/bookmarks
  }
}

import 'dart:convert';
import 'dart:io';

void main() async {
  final url = Uri.parse(
      'https://script.google.com/macros/s/AKfycbwAYg4oDtspNGFGMr6Bpt8YWYhF0Ao6tbYMCzriXCDjVF0EhZhH5g-MUmiTj3X3c-TiIw/exec?action=pull');
  final request = await HttpClient().getUrl(url);
  final response = await request.close();
  final stringData = await response.transform(utf8.decoder).join();
  final json = jsonDecode(stringData);
  final books = json['data']['books'] as List;
  if (books.isNotEmpty) {
    int emptyCount = 0;
    int dotCount = 0;
    for (var b in books) {
      if (b['book_name'] == null || b['book_name'].toString().trim().isEmpty) {
        emptyCount++;
        if (emptyCount <= 5) print('Empty Book: $b');
      }
      if (b['book_name'] == '.') dotCount++;
    }
    print('Total books: ${books.length}');
    print('Empty names: $emptyCount');
    print('Names as ".": $dotCount');
  } else {
    print('No books');
  }
}

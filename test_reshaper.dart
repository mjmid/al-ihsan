void main() {
  String reshapeBengali(String text) {
    text = text.replaceAll('\u09CB', '\u09C7\u09BE');
    text = text.replaceAll('\u09CC', '\u09C7\u09D7');

    final chars = text.split('');
    for (int i = 1; i < chars.length; i++) {
      final c = chars[i];
      if (c == '\u09BF' || c == '\u09C7' || c == '\u09C8') {
        int j = i - 1;
        while (j > 0 && chars[j-1] == '\u09CD') {
          j -= 2; 
        }
        if (j >= 0) {
          chars.removeAt(i);
          chars.insert(j, c);
        }
      }
    }
    return chars.join('');
  }

  print(reshapeBengali('তালিকা'));
  print(reshapeBengali('হাবিবুল্লাহ'));
}

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String baseUrl = 'https://openamharicbible.vercel.app/api/am';
const String outputDir = 'assets/bible';

// The list of 66 standard books to fetch
const Set<String> canonical66 = {
  'ዘፍ', 'ዘጸ', 'ዘሌ', 'ዘኍ', 'ዘዳ', 'መ.ኢያ', 'መ.መሣ', 'መ.ሩት', 'መ.ሳሙ1', 'መ.ሳሙ2', 'መ.ነገ1', 'መ.ነገ2', 'መ.ዜና1', 'መ.ዜና2', 'መ.ዕዝ', 'መ.ነህ', 'መ.አስ', 'መ.ኢዮ', 'መ.ዳ', 'መ.ምሳ', 'መ.መክ', 'መኃ.መኃ.ዘሰ', 'ትን.ኢሳ', 'ትን.ኤር', 'ሰቆ.ኤር', 'ት.ሕዝ', 'ት.ዳን', 'ት.ሆሴ', 'ት.ኢዮ', 'ት.አሞ', 'ት.አብ', 'ት.ዮና', 'ት.ሚክ', 'ት.ናሆ', 'ት.ዕንባ', 'ት.ሶፎ', 'ት.ሐጌ', 'ት.ዘካር', 'ት.ሚል',
  'ማቴ', 'ማር', 'ሉቃ', 'ዮሐ', 'ሐዋ', 'ሮሜ', '1 ቆሮ', '2 ቆሮ', 'ገላ', 'ኤፌሶ', 'ፊል', 'ቆላ', '1ተሰ', '2ተሰ', '1ጢሞ', '2ጢሞ', 'ቲቶ', 'ዕብ', 'ያዕ', '1ጴጥ', '2ጴጥ', '1ዮሐ', '2ዮሐ', '3ዮሐ', 'ይሁ', 'ዮራእ'
};

Future<void> main() async {
  print('Starting Bible download for 66 books...');
  
  final directory = Directory(outputDir);
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }

  try {
    final response = await http.get(Uri.parse('$baseUrl/books'));
    if (response.statusCode != 200) {
      print('Failed to fetch book list: ${response.statusCode}');
      return;
    }

    final List<dynamic> booksData = json.decode(response.body);
    
    for (var bookJson in booksData) {
      final String title = bookJson['title'];
      final String abbv = bookJson['abbv'];
      final int chapterCount = bookJson['chapters'];

      // We only fetch the standard 66 for bundling
      // Note: Philemon and Philippians share 'ፊል' in some API versions, 
      // and '2ዮሐ' might have an empty abbreviation. We differentiate them here.
      String effectiveAbbv = abbv;
      if (title == 'ወደ ፊልሞና') {
        effectiveAbbv = 'ፊልሞ';
      } else if (title == '2ዮሐ' && abbv.isEmpty) {
        effectiveAbbv = '2ዮሐ';
      }

      bool isCanonical = canonical66.contains(effectiveAbbv) || (effectiveAbbv == 'ፊልሞ' && canonical66.contains('ፊል'));
      if (!isCanonical) {
        print('Skipping non-canonical book: $title ($effectiveAbbv)');
        continue;
      }

      final String filePath = '$outputDir/$effectiveAbbv.json';
      final file = File(filePath);
      
      // If file exists, check if it's valid and has the correct number of chapters
      if (file.existsSync()) {
        try {
          final content = await file.readAsString();
          final data = json.decode(content);
          if (data['chapters'].length == chapterCount) {
            print('Skipping already downloaded and complete: $title');
            continue;
          } else {
            print('Re-downloading $title (incomplete: ${data['chapters'].length}/$chapterCount chapters)...');
          }
        } catch (e) {
          print('Corrupted file detected for $title, re-downloading...');
        }
      } else {
        print('Downloading $title ($effectiveAbbv) - $chapterCount chapters...');
      }

      Map<String, dynamic> bookData = {
        'title': title,
        'abbv': effectiveAbbv,
        'chapters': [],
      };

      for (int i = 1; i <= chapterCount; i++) {
        stdout.write('\r  Chapter $i/$chapterCount... ');
        try {
          final chResponse = await http.get(Uri.parse('$baseUrl/books/$effectiveAbbv/chapters/$i'));
          if (chResponse.statusCode == 200) {
            final chData = json.decode(chResponse.body);
            bookData['chapters'].add({
              'chapter': i,
              'verses': chData['verses'],
            });
          } else {
            print('\n  Failed to fetch chapter $i: ${chResponse.statusCode}');
          }
        } catch (e) {
          print('\n  Error fetching chapter $i: $e');
        }
        // Small delay to avoid hammering the API
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await file.writeAsString(json.encode(bookData));
      print('\n  Saved to $filePath');
    }

    print('\nDownload complete! ${Directory(outputDir).listSync().length} books saved.');
  } catch (e) {
    print('Critical Error: $e');
  }
}

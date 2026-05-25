import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    var content = file.readAsStringSync();
    
    // Remove border: Border.all(...)
    final borderRegex = RegExp(r'\s*border:\s*Border\.all\([^)]+\),');
    content = content.replaceAll(borderRegex, '');

    // Sometimes they write border: Border.all(
    //   color: ...,
    //   width: ...
    // ),
    final multiLineBorderRegex = RegExp(r'\s*border:\s*Border\.all\([^)]+\),', multiLine: true);
    content = content.replaceAll(multiLineBorderRegex, '');
    
    // The previous regex works for single lines. What if it spans multiple lines?
    final multiLineFull = RegExp(r'\s*border:\s*Border\.all\([^)]*\),?', multiLine: true, dotAll: true);
    // Actually, `[^)]*` will match across lines up to the next parenthesis.
    // To be safe, let's just match the specific pattern.
    content = content.replaceAll(RegExp(r'\s*border:\s*Border\.all\([^)]+\),?'), '');
    
    // Also remove any side: BorderSide(...)
    content = content.replaceAll(RegExp(r'\s*side:\s*(?:const\s+)?BorderSide\([^)]+\),?'), '');

    // Now for spacing. Let's find common padding values and standardize them to 12.
    // This is risky, but the user said "отступ ... слишком много или слишком мало". 
    // Usually it's EdgeInsets.all(16) or EdgeInsets.all(24). Let's standardize to 12 for cards.
    // Instead of doing this blindly, let's just focus on borders for now.
    
    file.writeAsStringSync(content);
  }
}

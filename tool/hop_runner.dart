library hop_runner;

import 'dart:io';
import 'package:bot/bot.dart';
import 'package:bot/hop.dart';
import 'package:bot/hop_tasks.dart';
import '../test/harness_console.dart' as test_console;

void main() {
  _assertKnownPath();

  addTask('hello', (ctx) {
    ctx.fine('Welcome to HOP!');
    return true;
  });

  addAsyncTask('test', createUnitTestTask(test_console.testCore));
  addAsyncTask('docs', getCompileDocsFunc('gh-pages', _getLibs));

  //
  // Dart2js
  //
  final paths = $(['click', 'drag', 'fract', 'spin'])
      .map((d) => "example/$d/${d}_demo.dart")
      .toList();
  paths.add('test/harness_browser.dart');

  addAsyncTask('dart2js', createDart2JsTask(paths));

  runHopCore();
}

void _assertKnownPath() {
  // since there is no way to determine the path of 'this' file
  // assume that Directory.current() is the root of the project.
  // So check for existance of /bin/hop_runner.dart
  final thisFile = new File('tool/hop_runner.dart');
  assert(thisFile.existsSync());
}

Future<SequenceCollection<String>> _getLibs() {
  final completer = new Completer<List<String>>();

  final lister = new Directory('lib').list();
  final libs = new List<String>();

  lister.onFile = (String file) {
    if(file.endsWith('.dart')) {
      // DARTBUG: http://code.google.com/p/dart/issues/detail?id=5460
      // exclude libs because of issues with dartdoc and sdk libs
      // in this case: unittest and args
      final forbidden = ['test', 'hop', 'hop_tasks'].map((n) => '$n.dart');
      if(forbidden.every((f) => !file.endsWith(f))) {
        libs.add(file);
      }
    }
  };

  lister.onDone = (bool done) {
    if(done) {
      completer.complete(libs);
    } else {
      completer.completeException('did not finish');
    }
  };

  lister.onError = (error) {
    completer.completeException(error);
  };

  return completer.future;
}

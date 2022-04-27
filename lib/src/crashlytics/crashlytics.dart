import 'dart:async';
import 'dart:isolate';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

Future<void> guardWithCrashlytics(
  void Function() mainFunction, {
  required FirebaseCrashlytics? crashlytics,
}) async {
  // Running the initialization code and [mainFunction] inside a guarded
  // zone, so that all errors (even those occurring in callbacks) are
  // caught and can be sent to Crashlytics.
  await runZonedGuarded<Future<void>>(() async {
    if (kDebugMode) {
      // Log more when in debug mode.
      Logger.root.level = Level.FINE;
    }
    // Subscribe to log messages.
    Logger.root.onRecord.listen((record) {
      final message = '${record.level.name}: ${record.time}: '
          '${record.loggerName}: '
          '${record.message}';

      debugPrint(message);
      // Add the message to the rotating Crashlytics log.
      crashlytics?.log(message);

      if (record.level >= Level.SEVERE) {
        crashlytics?.recordError(
            message, _filterStackTrace(StackTrace.current));
      }
    });

    // Pass all uncaught errors from the framework to Crashlytics.
    if (crashlytics != null) {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = crashlytics.recordFlutterError;
    }

    // To catch errors outside of the Flutter context, we attach an error
    // listener to the current isolate.
    Isolate.current.addErrorListener(RawReceivePort((pair) async {
      final List<dynamic> errorAndStacktrace = pair;
      await crashlytics?.recordError(
        errorAndStacktrace.first,
        errorAndStacktrace.last,
      );
    }).sendPort);

    // Run the actual code.
    mainFunction();
  }, (error, stack) {
    // This sees all errors that occur in the runZonedGuarded zone.
    debugPrint('ERROR: $error\n\n'
        'STACK:$stack');
    crashlytics?.recordError(error, stack);
  });
}

/// Takes a [stackTrace] and creates a new one, but without the lines that
/// have to do with this file and logging. This way, Crashlytics won't group
/// all messages that come from this file into one big heap just because
/// the head of the StackTrace is identical.
///
/// See this:
/// https://stackoverflow.com/questions/47654410/how-to-effectively-group-non-fatal-exceptions-in-crashlytics-fabrics.
StackTrace _filterStackTrace(StackTrace stackTrace) {
  StackTrace? filtered;
  try {
    final lines = filtered.toString().split('\n');
    final buf = StringBuffer();
    for (final line in lines) {
      if (line.contains('crashlytics.dart') ||
          line.contains('_BroadcastStreamController.java') ||
          line.contains('logger.dart')) {
        continue;
      }
      buf.writeln(line);
    }
    filtered = StackTrace.fromString(buf.toString());
  } catch (e) {
    debugPrint('Problem while filtering stack trace: $e');
  }

  return filtered ?? stackTrace;
}
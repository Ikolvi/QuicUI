import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:quicui_aot_cli/src/patch_diff_checker.dart';
import 'package:quicui_aot_cli/src/quicui_process.dart';
import 'package:quicui_aot_code_push_client/quicui_aot_code_push_client.dart';

class FakeArgResults extends Fake implements ArgResults {}

class FakeBaseRequest extends Fake implements http.BaseRequest {}

class FakeChannel extends Fake implements Channel {}

class FakeDiffStatus extends Fake implements DiffStatus {}

class FakeIOSink extends Fake implements IOSink {}

class FakeRelease extends Fake implements Release {}

class FakeReleaseArtifact extends Fake implements ReleaseArtifact {}

class FakeQuicuiProcess extends Fake implements QuicuiProcess {}

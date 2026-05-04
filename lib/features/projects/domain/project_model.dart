import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'project_model.g.dart';

@Riverpod(keepAlive: true)
class DummyProject extends _$DummyProject {
  @override
  int build() => 0;
}

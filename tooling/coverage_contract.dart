import 'dart:io';
import 'coverage_lib.dart';

void main(List<String> args) {
  if (args.length != 2 || args.first != '--id') {
    stderr.writeln(
      'usage: dart run tooling/coverage_contract.dart --id <module_id>',
    );
    exit(2);
  }
  final id = args[1];
  stdout.writeln(buildCoverageContract(id));
}

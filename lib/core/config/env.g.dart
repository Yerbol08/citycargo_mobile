// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'env.dart';

// **************************************************************************
// EnviedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// generated_from: .env
final class _Env {
  static const List<int> _enviedkeybaseUrl = <int>[
    26016203,
    1879541980,
    1255889557,
    3111971781,
    954133862,
    44118085,
    2486073161,
    3767386784,
    4108390366,
    3786921755,
    1476761625,
    1704439907,
    3687888463,
    171542218,
    374317639,
    1492436463,
    4159259780,
    3132242031,
    3204898938,
    3585158426,
  ];

  static const List<int> _envieddatabaseUrl = <int>[
    26016163,
    1879541928,
    1255889633,
    3111971765,
    954133781,
    44118143,
    2486073190,
    3767386767,
    4108390333,
    3786921842,
    1476761709,
    1704439834,
    3687888428,
    171542187,
    374317621,
    1492436360,
    4159259883,
    3132241985,
    3204898833,
    3585158496,
  ];

  static final String baseUrl = String.fromCharCodes(List<int>.generate(
    _envieddatabaseUrl.length,
    (int i) => i,
    growable: false,
  ).map((int i) => _envieddatabaseUrl[i] ^ _enviedkeybaseUrl[i]));

  static const List<int> _enviedkeywsUrl = <int>[
    4128634984,
    4223788031,
    1209355360,
    689588625,
    329036399,
    1771433911,
    3087714047,
    2259375545,
    3089051390,
    725868342,
    4208553926,
    433283724,
    411269598,
    1465600062,
    3540225662,
    821897477,
    3222966109,
    3215458195,
  ];

  static const List<int> _envieddatawsUrl = <int>[
    4128634911,
    4223787916,
    1209355283,
    689588651,
    329036352,
    1771433880,
    3087713948,
    2259375568,
    3089051274,
    725868367,
    4208553893,
    433283821,
    411269548,
    1465600089,
    3540225553,
    821897515,
    3222966070,
    3215458281,
  ];

  static final String wsUrl = String.fromCharCodes(List<int>.generate(
    _envieddatawsUrl.length,
    (int i) => i,
    growable: false,
  ).map((int i) => _envieddatawsUrl[i] ^ _enviedkeywsUrl[i]));

  static const List<int> _enviedkeysentryDsn = <int>[];

  static const List<int> _envieddatasentryDsn = <int>[];

  static final String sentryDsn = String.fromCharCodes(List<int>.generate(
    _envieddatasentryDsn.length,
    (int i) => i,
    growable: false,
  ).map((int i) => _envieddatasentryDsn[i] ^ _enviedkeysentryDsn[i]));
}

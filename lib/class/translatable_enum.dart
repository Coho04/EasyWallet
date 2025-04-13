import 'package:intl/intl.dart';

mixin TranslatableEnum
{
  String get value;
  String translate() => Intl.message(value);
}
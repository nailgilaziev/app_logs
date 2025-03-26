enum LoggerLevel {
  v("vrb"), // verbose
  i("inf"), // informational
  s("sig"), // significant / success
  w("wrn"), // warning
  e("err"); // error

  final String shortText;

  const LoggerLevel(this.shortText);
}

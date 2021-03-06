import 'dart:io';
import 'package:less_dart/less.dart';

main() {
  List<String> args = [];
  Less less = new Less();

  args.add('--no-color');

  //args.add('--clean-css="compatibility=*,-properties.colors"');
  args.add('--clean-css="compatibility=ie8"');
  args.add('less/cleancss/main-ie8.less');

  args.add('result/cleancss.css');
  less.transform(args).then((exitCode){
    stderr.write(less.stderr.toString());
    stdout.writeln('\nstdout:');
    stdout.write(less.stdout.toString());
  });
}
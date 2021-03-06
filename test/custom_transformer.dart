///
/// Custom Transformer example
///
/// Copy this file as \lib\transformer.dart and modified it as necessary
/// In pubspec.yaml:
///   transformers:
///   - <application name>
///
/// If you have other transformers:
///   copy this file as \lib\custom\custom_transformer.dart
///   and in pubspec.yaml:
///   transformers:
///   - <application name>\custom\custom_transformer
///
///   Replace <application name> by your application name
///

import 'package:barback/barback.dart';
import 'package:less_dart/transformer.dart';

class MyTransformer extends FileTransformer {

  MyTransformer(BarbackSettings settings):super(settings);

  MyTransformer.asPlugin(BarbackSettings settings): super(settings);

  @override
  void customOptions(LessOptions options) {
    options.definePlugin('myplugin', new MyPlugin()); //use @plugin "myplugin";  directive to load it
  }
}

class MyProcessor extends Processor {
  MyProcessor(options):super(options);

  String process(String input, Map options) {
      return '/* MyPlugin custom transformer post processor */\n' + input;
  }
}

class MyPlugin extends Plugin {
  MyPlugin(): super();

  install(PluginManager pluginManager) {
    Processor myProcessor = new MyProcessor(null);
    pluginManager.addPostProcessor(myProcessor);
  }
}
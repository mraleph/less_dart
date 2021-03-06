//source: tree/mixin-definition.js 2.5.0 20150419

part of tree.less;

class MixinDefinition extends Node with VariableMixin implements MakeImportantNode, MatchConditionNode {
  /// Same as Selector
  String name;

  /// Mixin params
  List<MixinArgs> params;

  /// Mixin body
  List<Node> rules;

  /// when (condition) {}
  Node condition;

  /// Arguments number is variable
  bool variadic;

  /// Same as name
  List<Node> selectors;

  //not in original
  int index;
  FileInfo currentFileInfo;

  var frames;

  /// Number of params
  int arity;

  bool evalFirst = true;

  bool isRuleset = true;

  Ruleset originalRuleset;

  /// Arguments number required
  int required;

  final String type = 'MixinDefinition';

  /// name, params, rules, condition, variadic, index, currentFileInfo, frames
  //index, currentFileInfo not in original. See order when calling with frames.
  MixinDefinition(String this.name, List<MixinArgs> this.params,
      List<Node> this.rules, Node this.condition, bool this.variadic,
      int this.index, FileInfo this.currentFileInfo, [this.frames]) {

    selectors = [new Selector([new Element(null, name, this.index, this.currentFileInfo)])];
    arity = this.params.length;

    required = params.fold(0, (count , p){
      if (p.name == null || (p.name != null && p.value == null)) {
        return count + 1;
      } else {
        return count;
      }
    });

    //this._lookups = {}; //inside VariableMixin

//2.3.1
//  var Definition = function (name, params, rules, condition, variadic, frames) {
//      this.name = name;
//      this.selectors = [new Selector([new Element(null, name, this.index, this.currentFileInfo)])];
//      this.params = params;
//      this.condition = condition;
//      this.variadic = variadic;
//      this.arity = params.length;
//      this.rules = rules;
//      this._lookups = {};
//      this.required = params.reduce(function (count, p) {
//          if (!p.name || (p.name && !p.value)) { return count + 1; }
//          else                                 { return count; }
//      }, 0);
//      this.frames = frames;
//  };
  }

  ///
  void accept(Visitor visitor) {
    if (params != null && params.isNotEmpty) {
      params = visitor.visitArray(params);
    }
    rules = visitor.visitArray(rules);
    if (condition != null) condition = visitor.visit(condition);

//2.3.1
//  Definition.prototype.accept = function (visitor) {
//      if (this.params && this.params.length) {
//          this.params = visitor.visitArray(this.params);
//      }
//      this.rules = visitor.visitArray(this.rules);
//      if (this.condition) {
//          this.condition = visitor.visit(this.condition);
//      }
//  };
  }

// VariableMixin

//variable:  function (name) { return this.parent.variable.call(this, name); },
//
//variables() {
//    variables: function ()     { return this.parent.variables.call(this); },
//}
//
//  find() {
////    find:      function ()     { return this.parent.find.apply(this, arguments); },
//  }
//
//  rulesets() {
////    rulesets:  function ()     { return this.parent.rulesets.apply(this); },
//  }

  ///
  /// Build a Ruleset where the rules are the mixin params evaluated
  /// Build evaldArguments
  ///
  Ruleset evalParams(Contexts context, Contexts mixinEnv, List<MixinArgs> args, List evaldArguments) {
    Ruleset frame = new Ruleset(null, null);
    List<Node> varargs;
    MixinArgs arg;
    List<MixinArgs> params = this.params.sublist(0);
    int i, j;
    var val;
    String name;
    bool isNamedFound;
    int argIndex;
    int argsLength = 0;

    //Fill with nulls the list
    evaldArguments.length = math.max(
        (params != null) ? params.length : 0,
        (args != null)   ? args.length : 0);

    if (mixinEnv.frames != null && mixinEnv.frames.isNotEmpty && (mixinEnv.frames[0] as VariableMixin).functionRegistry != null) {
      frame.functionRegistry = new FunctionRegistry.inherit((mixinEnv.frames[0] as VariableMixin).functionRegistry);
    }

    mixinEnv = new Contexts.eval(mixinEnv,
                             [frame]..addAll(mixinEnv.frames));

    if (args != null) {
      args = args.sublist(0);
      argsLength = args.length;

      for (i = 0; i < args.length; i++) {
        arg = args[i];
        name = (arg != null) ? arg.name : null;
        if (name != null) {
          isNamedFound = false;
          for (j = 0; j < params.length; j++) {
            if (evaldArguments[j] == null && name == params[j].name) {
              evaldArguments[j] = arg.value.eval(context);
              frame.prependRule(new Rule(name, arg.value.eval(context)));
              isNamedFound = true;
              break;
            }
          }
          if (isNamedFound) {
            args.removeAt(i);
            i--;
            continue;
          } else {
            throw new LessExceptionError(new LessError(
                type: 'Runtime',
                message: 'Named argument for ${this.name} ${args[i].name}  not found'
                ));
          }
        }
      }
    }

    argIndex = 0;
    for (i = 0; i < params.length; i++) {
      if (i < evaldArguments.length && evaldArguments[i] != null) continue;

      arg = (args != null && argIndex < args.length) ? args[argIndex] : null;

      if ((name = params[i].name) != null) {
        if (params[i].variadic) {
          varargs = [];
          for (j = argIndex; j < argsLength; j++) {
            varargs.add(args[j].value.eval(context));
          }
          frame.prependRule(new Rule(name, new Expression(varargs).eval(context)));
        } else {
          val = (arg != null) ? arg.value : null;
          if (val != null) {
            val = val.eval(context);
          } else if (params[i].value != null) {
            val = params[i].value.eval(mixinEnv);
            frame.resetCache();
          } else {
            throw new LessExceptionError(new LessError(
                type: 'Runtime',
                message: 'wrong number of arguments for ${this.name} (${argsLength} for ${this.arity})'));
          }
          frame.prependRule(new Rule(name, val));
          evaldArguments[i] = val;
        }
      }
      if (params[i].variadic && args != null) {
        for (j = argIndex; j < argsLength; j++) {
          evaldArguments[j] = args[j].value.eval(context);
        }
      }
      argIndex++;
    }

    // Remove null elements at the end
    while (evaldArguments.isNotEmpty) {
      if (evaldArguments.last == null) {
        evaldArguments.removeLast();
      } else {
        break;
      }
    }
    return frame;

//2.4.0 20150323
//  Definition.prototype.evalParams = function (context, mixinEnv, args, evaldArguments) {
//      /*jshint boss:true */
//      var frame = new Ruleset(null, null),
//          varargs, arg,
//          params = this.params.slice(0),
//          i, j, val, name, isNamedFound, argIndex, argsLength = 0;
//
//      if (mixinEnv.frames && mixinEnv.frames[0] && mixinEnv.frames[0].functionRegistry) {
//          frame.functionRegistry = mixinEnv.frames[0].functionRegistry.inherit();
//      }
//      mixinEnv = new contexts.Eval(mixinEnv, [frame].concat(mixinEnv.frames));
//
//      if (args) {
//          args = args.slice(0);
//          argsLength = args.length;
//
//          for (i = 0; i < argsLength; i++) {
//              arg = args[i];
//              if (name = (arg && arg.name)) {
//                  isNamedFound = false;
//                  for (j = 0; j < params.length; j++) {
//                      if (!evaldArguments[j] && name === params[j].name) {
//                          evaldArguments[j] = arg.value.eval(context);
//                          frame.prependRule(new Rule(name, arg.value.eval(context)));
//                          isNamedFound = true;
//                          break;
//                      }
//                  }
//                  if (isNamedFound) {
//                      args.splice(i, 1);
//                      i--;
//                      continue;
//                  } else {
//                      throw { type: 'Runtime', message: "Named argument for " + this.name +
//                          ' ' + args[i].name + ' not found' };
//                  }
//              }
//          }
//      }
//      argIndex = 0;
//      for (i = 0; i < params.length; i++) {
//          if (evaldArguments[i]) { continue; }
//
//          arg = args && args[argIndex];
//
//          if (name = params[i].name) {
//              if (params[i].variadic) {
//                  varargs = [];
//                  for (j = argIndex; j < argsLength; j++) {
//                      varargs.push(args[j].value.eval(context));
//                  }
//                  frame.prependRule(new Rule(name, new Expression(varargs).eval(context)));
//              } else {
//                  val = arg && arg.value;
//                  if (val) {
//                      val = val.eval(context);
//                  } else if (params[i].value) {
//                      val = params[i].value.eval(mixinEnv);
//                      frame.resetCache();
//                  } else {
//                      throw { type: 'Runtime', message: "wrong number of arguments for " + this.name +
//                          ' (' + argsLength + ' for ' + this.arity + ')' };
//                  }
//
//                  frame.prependRule(new Rule(name, val));
//                  evaldArguments[i] = val;
//              }
//          }
//
//          if (params[i].variadic && args) {
//              for (j = argIndex; j < argsLength; j++) {
//                  evaldArguments[j] = args[j].value.eval(context);
//              }
//          }
//          argIndex++;
//      }
//
//      return frame;
//  };
  }

  // ---- begin MakeImportantNode

  ///
  MixinDefinition makeImportant() {
    List<Node> rules = (this.rules == null)
        ? this.rules
        : this.rules.map((r){
          if (r is MakeImportantNode) {
            return r.makeImportant();
          } else {
            return r;
          }
        }).toList();
    return new MixinDefinition(name, params, rules, condition,
        variadic, index, currentFileInfo, frames);

//2.4.0
//  Definition.prototype.makeImportant = function() {
//      var rules = !this.rules ? this.rules : this.rules.map(function (r) {
//          if (r.makeImportant) {
//              return r.makeImportant(true);
//          } else {
//              return r;
//          }
//      });
//      var result = new Definition (this.name, this.params, rules, this.condition, this.variadic, this.frames);
//      return result;
//  };
  }

  // ---- end MakeImportantNode

  ///
  MixinDefinition eval(Contexts context) {
    var frames = (this.frames != null) ? this.frames : context.frames.sublist(0);
    return new MixinDefinition(name, params, rules, condition,
        variadic, index, currentFileInfo, frames);

//2.3.1
//  Definition.prototype.eval = function (context) {
//      return new Definition(this.name, this.params, this.rules, this.condition, this.variadic, this.frames || context.frames.slice(0));
//  };
  }

  ///
  Ruleset evalCall(Contexts context, List<MixinArgs> args, bool important) {
    List _arguments = [];
    List<Node> mixinFrames = (frames != null) ? (frames.sublist(0)..addAll(context.frames)) : context.frames;
    Ruleset frame = evalParams(context, new Contexts.eval(context, mixinFrames), args, _arguments);
    List<Node> rules;
    Ruleset ruleset;

    frame.prependRule(new Rule('@arguments', new Expression(_arguments).eval(context)));

    rules = this.rules.sublist(0);

    ruleset = new Ruleset(null, rules);
    ruleset.originalRuleset = this;
    ruleset.id = id;
    ruleset = ruleset.eval(new Contexts.eval(context, [this, frame]..addAll(mixinFrames)));
    if (important) {
      ruleset = ruleset.makeImportant();
    }
    return ruleset;

//2.4.0
//  Definition.prototype.evalCall = function (context, args, important) {
//      var _arguments = [],
//          mixinFrames = this.frames ? this.frames.concat(context.frames) : context.frames,
//          frame = this.evalParams(context, new contexts.Eval(context, mixinFrames), args, _arguments),
//          rules, ruleset;
//
//      frame.prependRule(new Rule('@arguments', new Expression(_arguments).eval(context)));
//
//      rules = this.rules.slice(0);
//
//      ruleset = new Ruleset(null, rules);
//      ruleset.originalRuleset = this;
//      ruleset = ruleset.eval(new contexts.Eval(context, [this, frame].concat(mixinFrames)));
//      if (important) {
//          ruleset = ruleset.makeImportant();
//      }
//      return ruleset;
//  };
  }

  //--- MatchConditionNode

  ///
  bool matchCondition(List<MixinArgs> args, Contexts context) {
    List thisFrames = (this.frames != null) ? (this.frames.sublist(0)..addAll(context.frames)) : context.frames;
    List frames = [evalParams(context, new Contexts.eval(context, thisFrames), args, [])] // the parameter variables
      ..addAll(this.frames != null ? this.frames : [] ) // the parent namespace/mixin frames
      ..addAll(context.frames); // the current environment frames
    if (condition != null && !condition.eval(new Contexts.eval(context, frames))) return false;
    return true;

//2.5.0 20150419
//  Definition.prototype.matchCondition = function (args, context) {
//      if (this.condition && !this.condition.eval(
//          new contexts.Eval(context,
//              [this.evalParams(context, /* the parameter variables*/
//                  new contexts.Eval(context, this.frames ? this.frames.concat(context.frames) : context.frames), args, [])]
//              .concat(this.frames || []) // the parent namespace/mixin frames
//              .concat(context.frames)))) { // the current environment frames
//          return false;
//      }
//      return true;
//  };
  }

  ///
  /// Check arguments call is according mixin definition
  ///
  bool matchArgs(List<MixinArgs> args, Contexts context) {
    int argsLength = 0;
    if (args != null) argsLength = args.length;
    int len;

    if (!this.variadic) {
      if (argsLength < required)       return false;
      if (argsLength > params.length)  return false;
    } else {
      if (argsLength < (required - 1)) return false;
    }

    len = math.min(argsLength, arity);

    for (int i = 0; i < len; i++) {
      if (params[i].name == null && !params[i].variadic) {
        if (args[i].value.eval(context).toCSS(context) != params[i].value.eval(context).toCSS(context)) {
          return false;
        }
      }
    }
    return true;

//2.3.1
//  Definition.prototype.matchArgs = function (args, context) {
//      var argsLength = (args && args.length) || 0, len;
//
//      if (! this.variadic) {
//          if (argsLength < this.required)                               { return false; }
//          if (argsLength > this.params.length)                          { return false; }
//      } else {
//          if (argsLength < (this.required - 1))                         { return false; }
//      }
//
//      len = Math.min(argsLength, this.arity);
//
//      for (var i = 0; i < len; i++) {
//          if (!this.params[i].name && !this.params[i].variadic) {
//              if (args[i].value.eval(context).toCSS() != this.params[i].value.eval(context).toCSS()) {
//                  return false;
//              }
//          }
//      }
//      return true;
//  };
  }
}
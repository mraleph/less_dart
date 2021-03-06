//source: less/tree/selector.js 2.5.0

part of tree.less;

/// Selectors such as body, h1, ...
class Selector extends Node implements GetIsReferencedNode, MarkReferencedNode {
  List<Element> elements; //body, ...
  List<Node> extendList;
  Node condition;
  int index;
  FileInfo currentFileInfo;
  bool isReferenced = false;

  String _css;

  /// Cached string elements List, such as ['#selector1', .., '.selectorN']
  List<String> _elements;

  bool evaldCondition = false;
  bool mediaEmpty = false;

  /// String Elements List
  List<String> get strElements {
    if (_elements == null) cacheElements();
    return _elements;
  }

  final String type = 'Selector';

  ///
  Selector (List<Node> this.elements, [List<Node> this.extendList, Node this.condition, int this.index,
                            FileInfo this.currentFileInfo, bool this.isReferenced]) {
    if (this.currentFileInfo == null) this.currentFileInfo = new FileInfo();
    if (this.condition == null) this.evaldCondition = true;

//2.3.1
//  var Selector = function (elements, extendList, condition, index, currentFileInfo, isReferenced) {
//      this.elements = elements;
//      this.extendList = extendList;
//      this.condition = condition;
//      this.currentFileInfo = currentFileInfo || {};
//      this.isReferenced = isReferenced;
//      if (!condition) {
//          this.evaldCondition = true;
//      }
//  };
  }

  ///
  void accept(Visitor visitor) {
    if (elements != null) elements = visitor.visitArray(elements);
    if (extendList != null) extendList = visitor.visitArray(extendList);
    if (condition != null) condition = visitor.visit(condition);

//2.3.1
//  Selector.prototype.accept = function (visitor) {
//      if (this.elements) {
//          this.elements = visitor.visitArray(this.elements);
//      }
//      if (this.extendList) {
//          this.extendList = visitor.visitArray(this.extendList);
//      }
//      if (this.condition) {
//          this.condition = visitor.visit(this.condition);
//      }
//  };
  }

  ///
  Selector createDerived(List<Element> elements, [List<Node> extendList, bool evaldCondition]) {
    evaldCondition = (evaldCondition != null)? evaldCondition : this.evaldCondition;

    Selector newSelector = new Selector(elements, extendList != null ? extendList : this.extendList, null,
        index, currentFileInfo, isReferenced)
        ..evaldCondition = evaldCondition
        ..mediaEmpty = mediaEmpty;
    return newSelector;

//2.3.1
//  Selector.prototype.createDerived = function(elements, extendList, evaldCondition) {
//      evaldCondition = (evaldCondition != null) ? evaldCondition : this.evaldCondition;
//      var newSelector = new Selector(elements, extendList || this.extendList, null, this.index, this.currentFileInfo, this.isReferenced);
//      newSelector.evaldCondition = evaldCondition;
//      newSelector.mediaEmpty = this.mediaEmpty;
//      return newSelector;
//  };
  }

  ///
  List<Selector> createEmptySelectors() {
    Element el = new Element('', '&', index, currentFileInfo);
    List<Selector> sels = [new Selector([el], null, null, index, currentFileInfo)];
    sels[0].mediaEmpty = true;
    return sels;

//2.4.0+
//  Selector.prototype.createEmptySelectors = function() {
//      var el = new Element('', '&', this.index, this.currentFileInfo),
//          sels = [new Selector([el], null, null, this.index, this.currentFileInfo)];
//      sels[0].mediaEmpty = true;
//      return sels;
//  };
  }

  ///
  /// Compares this Selector with the [other] Selector
  ///
  /// Returns number of matched Selector elements if match. 0 means not match.
  ///
  int match(Selector other) {
    List<String> thisStrElements = this.strElements;
    List<String> otherStrElements = other.strElements;

    if (otherStrElements.isEmpty || thisStrElements.length < otherStrElements.length) {
      return 0;
    } else {
      for (int i = 0; i < otherStrElements.length; i++) {
        if (thisStrElements[i] != otherStrElements[i]) return 0;
      }
    }
    return otherStrElements.length;

// -- VALID IMPLEMENTATION --
//    List<Element> elements = this.elements;
//    int len = elements.length;
//    int olen; //other elements.length
//
//    other.cacheElements(); //Create if not, other._elements
//
//    olen = other._elements.length;
//    if (olen == 0 || len < olen) {
//      return 0;
//    } else {
//      for (int i = 0; i < olen; i++) {
//        if (elements[i].value != other._elements[i]) return 0;
//      }
//    }
//
//    return olen;

//2.3.1
//  Selector.prototype.match = function (other) {
//      var elements = this.elements,
//          len = elements.length,
//          olen, i;
//
//      other.CacheElements();
//
//      olen = other._elements.length;
//      if (olen === 0 || len < olen) {
//          return 0;
//      } else {
//          for (i = 0; i < olen; i++) {
//              if (elements[i].value !== other._elements[i]) {
//                  return 0;
//              }
//          }
//      }
//
//      return olen; // return number of matched elements
//  };
  }

  ///
  /// Creates this._elements as a String List of selector names
  ///
  /// Example: ['#sel1', '.sel2', ...]
  ///
  void cacheElements() {
    String css;
    RegExp re = new RegExp(r'[,&#\*\.\w-]([\w-]|(\\.))*');

    if (_elements != null) return; // cache exist

    css = elements.map((Element v){
      return v.combinator.value
          + ((v.value is String) ? v.value : (v.value as Node).toCSS(null)); //ex. v.value Dimension
    }).toList().join('');

    Iterable<Match> matchs = re.allMatches(css);
    if (matchs != null) {
      _elements = matchs.map((m) => m[0]).toList();
      if (_elements.isNotEmpty && _elements[0] == '&') _elements.removeAt(0);
    } else {
      _elements = [];
    }


//2.3.1
//  Selector.prototype.CacheElements = function() {
//      if (this._elements) {
//          return;
//      }
//
//      var elements = this.elements.map( function(v) {
//          return v.combinator.value + (v.value.value || v.value);
//      }).join("").match(/[,&#\*\.\w-]([\w-]|(\\.))*/g);
//
//      if (elements) {
//          if (elements[0] === "&") {
//              elements.shift();
//          }
//      } else {
//          elements = [];
//      }
//
//      this._elements = elements;
//  };
  }

  ///
  bool isJustParentSelector() => !mediaEmpty
                              && elements.length == 1
                              && elements[0].value == '&'
                              && (   elements[0].combinator.value == ' '
                                  || elements[0].combinator.value == '');

  //2.3.1
//  Selector.prototype.isJustParentSelector = function() {
//      return !this.mediaEmpty &&
//          this.elements.length === 1 &&
//          this.elements[0].value === '&' &&
//          (this.elements[0].combinator.value === ' ' || this.elements[0].combinator.value === '');
//  };

  ///
  Selector eval(Contexts context) {
    bool evaldCondition;
    if (condition != null) evaldCondition = condition.eval(context); //evaldCondition null is ok
    List<Element> elements = this.elements;
    List<Node> extendList = this.extendList;

    if (elements != null) elements = elements.map((e)=> e.eval(context)).toList();
    if (extendList != null) extendList = extendList.map((extend) => extend.eval(context)).toList();

    return this.createDerived(elements, extendList, evaldCondition);

//2.3.1
//  Selector.prototype.eval = function (context) {
//      var evaldCondition = this.condition && this.condition.eval(context),
//          elements = this.elements, extendList = this.extendList;
//
//      elements = elements && elements.map(function (e) { return e.eval(context); });
//      extendList = extendList && extendList.map(function(extend) { return extend.eval(context); });
//
//      return this.createDerived(elements, extendList, evaldCondition);
//  };
  }

  ///
  /// Writes Selector as String in [output]:
  ///  ' selector'. White space prefixed.
  ///
  void genCSS(Contexts context, Output output) {
    Element element;

    if ((context == null || !context.firstSelector) && elements[0].combinator.value == '') {
      output.add(' ', currentFileInfo, index);
    }
    if (!isNotEmpty(_css)) {
      // todo caching? speed comparison?
      for (int i = 0; i < elements.length; i++) {
        element = elements[i];
        element.genCSS(context, output);
      }
    }

//2.3.1
//  Selector.prototype.genCSS = function (context, output) {
//      var i, element;
//      if ((!context || !context.firstSelector) && this.elements[0].combinator.value === "") {
//          output.add(' ', this.currentFileInfo, this.index);
//      }
//      if (!this._css) {
//          //todo caching? speed comparison?
//          for(i = 0; i < this.elements.length; i++) {
//              element = this.elements[i];
//              element.genCSS(context, output);
//          }
//      }
//  };
  }

  //--- MarkReferencedNode -------------

  ///
  void markReferenced() {
    isReferenced = true;

//2.3.1
//  Selector.prototype.markReferenced = function () {
//      this.isReferenced = true;
//  };
  }

  ///
  bool getIsReferenced() => !currentFileInfo.reference || isTrue(isReferenced);

//2.3.1
//  Selector.prototype.getIsReferenced = function() {
//      return !this.currentFileInfo.reference || this.isReferenced;
//  };

  ///
  bool getIsOutput() => evaldCondition;

//2.3.1
//  Selector.prototype.getIsOutput = function() {
//      return this.evaldCondition;
//  };
}
//source: less/visitor.js 2.4.0

part of visitor.less;

class Visitor extends VisitorBase{
  VisitorBase _implementation; //Join_Selector_visitor, ...
  VisitArgs _visitArgs = new VisitArgs(true);

  ///
  //2.3.1 ok
  Visitor(VisitorBase this._implementation);

  /// Process a [node] and the subtree
  //2.3.1 ok
  visit(node) {
    if (node == null) return node;
    if (node is! Node) return node;

    this._visitArgs.visitDeeper = true;

    Function func = this._implementation.visitFtn(node);
    Function funcOut = this._implementation.visitFtnOut(node);

    if (func != null) {
      var newNode = func(node, this._visitArgs); //Node or List
      if (this._implementation.isReplacing) node = newNode;
    }

    if (node is List && node.isEmpty) return null; //TODO 2.3.1 remove - test 23

    if (this._visitArgs.visitDeeper && node != null && (node is Node)) node.accept(this);

    if (funcOut != null) funcOut(node);

    return node;

//2.3.1
//  visit: function(node) {
//      if (!node) {
//          return node;
//      }
//
//      var nodeTypeIndex = node.typeIndex;
//      if (!nodeTypeIndex) {
//          return node;
//      }
//
//      var visitFnCache = this._visitFnCache,
//          impl = this._implementation,
//          aryIndx = nodeTypeIndex << 1,
//          outAryIndex = aryIndx | 1,
//          func = visitFnCache[aryIndx],
//          funcOut = visitFnCache[outAryIndex],
//          visitArgs = _visitArgs,
//          fnName;
//
//      visitArgs.visitDeeper = true;
//
//      if (!func) {
//          fnName = "visit" + node.type;
//          func = impl[fnName] || _noop;
//          funcOut = impl[fnName + "Out"] || _noop;
//          visitFnCache[aryIndx] = func;
//          visitFnCache[outAryIndex] = funcOut;
//      }
//
//      if (func !== _noop) {
//          var newNode = func.call(impl, node, visitArgs);
//          if (impl.isReplacing) {
//              node = newNode;
//          }
//      }
//
//      if (visitArgs.visitDeeper && node && node.accept) {
//          node.accept(this);
//      }
//
//      if (funcOut != _noop) {
//          funcOut.call(impl, node);
//      }
//
//      return node;
//  },
  }

  ///
  //2.3.1 ok
  List visitArray(List nodes, [bool nonReplacing = false]) {
    if (nodes == null) return nodes;

    // Non-replacing
    if (nonReplacing || !this._implementation.isReplacing) {
      for (int i = 0; i < nodes.length; i++) this.visit(nodes[i]);
      return nodes;
    }

    // Replacing
    List out = [];
    for (int i = 0; i < nodes.length; i++) {
      var evald = this.visit(nodes[i]);
      if (evald == null) continue;

      if (evald is! List) {
        out.add(evald);
      } else if (evald.isNotEmpty) {
        this.flatten(evald, out);
      }
    }
    return out;

//2.3.1
//  visitArray: function(nodes, nonReplacing) {
//      if (!nodes) {
//          return nodes;
//      }
//
//      var cnt = nodes.length, i;
//
//      // Non-replacing
//      if (nonReplacing || !this._implementation.isReplacing) {
//          for (i = 0; i < cnt; i++) {
//              this.visit(nodes[i]);
//          }
//          return nodes;
//      }
//
//      // Replacing
//      var out = [];
//      for (i = 0; i < cnt; i++) {
//          var evald = this.visit(nodes[i]);
//          if (evald === undefined) { continue; }
//          if (!evald.splice) {
//              out.push(evald);
//          } else if (evald.length) {
//              this.flatten(evald, out);
//          }
//      }
//      return out;
//  },
  }

  ///
  /// Converts a mix of Node and List<Node> to List<Node>
  /// arr == [Node, [Node, Node...]] -> [Node, Node, Node, ...]
  ///
  //2.3.1 ok
  List<Node> flatten(List<Node> arr, List<Node> out) {
    if (out == null) out = [];

    var item; //Node or List
    int nestedCnt;
    var nestedItem;

    for (int i = 0 ; i < arr.length; i++) {
      item = arr[i];
      if (item == null) continue;
      if (item is Node) {
        out.add(item);
        continue;
      }

      nestedCnt = (item as List).length;
      for (int j = 0; j < nestedCnt; j++) {
        nestedItem = (item as List)[j];
        if (nestedItem == null) continue;
        if (nestedItem is Node) {
          out.add(nestedItem);
        } else if (nestedItem is List) {
          this.flatten(nestedItem, out);
        }
      }
    }

    return out;

//2.3.1
//  flatten: function(arr, out) {
//      if (!out) {
//          out = [];
//      }
//
//      var cnt, i, item,
//          nestedCnt, j, nestedItem;
//
//      for (i = 0, cnt = arr.length; i < cnt; i++) {
//          item = arr[i];
//          if (item === undefined) {
//              continue;
//          }
//          if (!item.splice) {
//              out.push(item);
//              continue;
//          }
//
//          for (j = 0, nestedCnt = item.length; j < nestedCnt; j++) {
//              nestedItem = item[j];
//              if (nestedItem === undefined) {
//                  continue;
//              }
//              if (!nestedItem.splice) {
//                  out.push(nestedItem);
//              } else if (nestedItem.length) {
//                  this.flatten(nestedItem, out);
//              }
//          }
//      }
//
//      return out;
//  }
  }
}
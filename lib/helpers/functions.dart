/*****************************************************************************
 * Copyright 2015 Marek Suscak
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 *****************************************************************************/
library spreadsheet.helper;

import 'dart:html';

typedef void InsertLaterFunction();

/// Removes [node] from the DOM for later insertion
/// with a function returned.
InsertLaterFunction removeToInsertLater(Node node) {
  var parentNode = node.parent;
  var nextSibling = node.nextNode;
  parentNode.children.remove(node);

  return () {
    if(nextSibling != null) {
      parentNode.insertBefore(node, nextSibling);
    } else {
      parentNode.append(node);
    }
  };
}

/// Converts [colId] to excel column code.
String toExcelColumnCode(int colId) {
  String result = "";

  // [colId] param is indexed from 0 so we need to add 1
  colId += 1;

  while(colId > 0) {
    int letterNumber = (colId - 1) % 26;
    result = "${new String.fromCharCode(letterNumber + 65)}$result";
    colId = ((colId - (letterNumber + 1)) / 26).truncate();
  }

  return result;
}

/// Converts [colId] and [rowId] to cell coordinates.
String toExcelCoord(int colId, int rowId) {
  return "${toExcelColumnCode(colId)}${rowId+1}";
}

/// Returns the [value] in pixels.
String toPx(int value) {
  return "${value}px";
}
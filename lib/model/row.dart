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
part of spreadsheet.model;

/**
 * Represents one spreadsheet row configuration object
 */
class Row {
  static final defaultHeight = 21;

  /// Used to restore height to its original minimum value when adjusting row height
  int preservedMinimumHeight = defaultHeight;

  int _height = defaultHeight;
  int get height => _height;
  void set height(int height) {
    _height = height;
    preservedMinimumHeight = _height;
    _invalidate();
  }

  List<TableRowElement> _trElements;
  List<TableRowElement> get trElements => _trElements;
  void set trElements(List<TableRowElement> trElements) {
    _trElements = trElements;
    _invalidate();
  }

  void _invalidate() {
    if(_trElements == null) {
      return;
    }

    _trElements.forEach((e) => e.style.height = "${_height}px");
  }
}
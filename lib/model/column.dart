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
 * Represents one spreadsheet column configuration object
 */
class Column {
  int _width = 100;
  int get width => _width;
  void set width(int width) {
    _width = width;
    _invalidate();
  }

  List<TableColElement> _colElements;
  List<TableColElement> get colElements => _colElements;
  void set colElements(List<TableColElement> colElements) {
    _colElements = colElements;
    _invalidate();
  }

  void _invalidate() {
    if(_colElements == null) {
      return;
    }

    _colElements.forEach((e) => e.style.width = "${_width}px");
  }
}
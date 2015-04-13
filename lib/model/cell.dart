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
 * Represents one spreadsheet cell configuration object
 */
class Cell {
  static final Logger _logger = new Logger('Cell');

  /// Cell value
  Object _value = null;
  Object get value => _value;
  
  int get column => int.parse(this.element.attributes['colid']);
  int get row => int.parse(this.element.parent.attributes['rowid']);
    
  void set value(Object value) {
    _value = value;

    if(_renderer == null) {
      return;
    }

    _invalidate();
  }

  /// Cell <td> element reference
  TableCellElement _element;
  TableCellElement get element => _element;
  void set element(TableCellElement element) {
    _element = element;

    if(_renderer == null) {
      return;
    }

    _invalidate();
  }

  /// Name of the renderer to be created for the cell
  CellRenderer _renderer;
  CellRenderer get renderer => _renderer;
  void set renderer(CellRenderer renderer) {
    _renderer = renderer;

    if(_element == null) {
      return;
    }

    // push value
    _invalidate();
  }

  /// Name of the editor to be assigned when activating the cell
  Symbol editorName = #text;

  /// If the cell is readonly which means readonly CSS class is applied and activation is forbidden
  bool _readonly = false;
  bool get readonly => _readonly;
  void set readonly(bool readonly) {
    if(_readonly == readonly) {
      return;
    }

    _readonly = readonly;

    _ensureCssClassState("readonly", _readonly);
  }

  Cell(this._renderer);
  Cell.fromJson(Map json) : _value = json['value'], _renderer = json['renderer'], editorName = json['editorName'], _readonly = json['readonly'];
  Map toJson() => { 'value': _value, 'rendererName': _renderer, 'editorName': editorName, 'readonly': _readonly };

  void _ensureCssClassState(String cssClass, bool state) {
    if(_element == null) {
      return;
    }

    (state ? _element.classes.add(cssClass) : _element.classes.removeWhere((c) => c == cssClass));
  }
  
  void _invalidate() {
    _element.children.clear();
    var node = _renderer.render(value);
    if (node != null) {
      _element.append(node);
    }
  }
}

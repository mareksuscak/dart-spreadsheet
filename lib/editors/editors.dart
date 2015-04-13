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
library spreadsheet.editors;

import 'package:polymer/polymer.dart';
import 'package:logging/logging.dart';
import 'dart:html';
import 'dart:async';

part 'text_cell_editor.dart';

/**
 * Represents abstract cell editor. When ready to change value, fire edit-complete
 * event with detail set to the new value.
 */
abstract class CellEditor {
  bool isActive = false;
  Object originalValue;
  bool get valueHasChanged => originalValue != this.pullValue();

  /**
   * Note: this function must handle null values properly as nulls are used to clear the data.
   */
  void pushValue(Object value) {
    originalValue = value;
  }

  Object pullValue();

  void activate() {
    isActive = true;
  }
  void deactivate() {
    isActive = false;
  }
}

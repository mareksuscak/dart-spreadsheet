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
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:logging/logging.dart';
import 'package:spreadsheet/spreadsheet.dart';
import 'package:spreadsheet/model/model.dart';

@CustomTag('app-element')
class AppElement extends PolymerElement {

  static final Logger _logger = new Logger('App-Element');

  Spreadsheet get spreadsheet => $['spreadsheet'];

  AppElement.created() : super.created() {
    // ShadowDOM NOT ready
  }

  void cellChangedAction(Event event, Object detail) {
    Map data = detail as Map;

    _logger.info("Cell [colId:${data['colId']};rowId:${data['rowId']}] value has been changed to '${data['value']}'.");
  }

  @override
  void attached() {
    super.attached();

    // configure frozen rows and columns
    spreadsheet.frozenColsLeft = 6;
    spreadsheet.frozenRowsTop = 3;
    spreadsheet.colsCount = 50;
    spreadsheet.rowsCount = 50;

    // renders the spreadsheet
    spreadsheet.render().then((_) {
      // cell insertion
      spreadsheet.setCellValueAt(0,0, "cell val");

      // clear range data
      spreadsheet.clear(new CellRange(0,0,0,19));

      // horizontal insertion
      spreadsheet.insertDataAt(0,1, ["horiz data", "horiz data", "horiz data", "horiz data"]);

      // clear data
      spreadsheet.clear();

      // vertical insertion
      spreadsheet.insertDataAt(1,1, ["vert data", "vert data", "vert data", "vert data"], vertical: true);

      // configure cell properties
      spreadsheet.configureCells(new CellRange(1,1), (int rowId, int colCode, Cell cell) {
        cell.readonly = true;

        // defining CSS styles for the cell
        cell.element.style
          ..borderRightColor = "black"
          ..borderBottomColor = "black";
      });

      spreadsheet.configureCells(new CellRange(0,2), (int rowId, int colCode, Cell cell) {
        cell.value = "test";
      });

      // configure row properties
      spreadsheet.configureRows(0, 0, (int rowId, Row row) {
        row.height = 50;
      });

      // configure columns
      spreadsheet.configureColumns(2, 2, (int colCode, Column col) {
        col.width = 50;
      });

    }).then((_) {
      // example of re-rendering the sheet
      // spreadsheet.colsCount = 10;
      // spreadsheet.rowsCount = 37;
      // spreadsheet.frozenColsLeft = 1;
      // spreadsheet.frozenRowsTop = 1;
      //
      // spreadsheet.render();
    });
  }
}
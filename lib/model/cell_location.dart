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
 * Represents the immutable cell location in the spreadsheet.
 */
class CellLocation {
  int _rowId = -1;
  int get rowId => _rowId;

  int _colId = -1;
  int get colId => _colId;

  CellLocation(int colId, int rowId) : _rowId = rowId, _colId = colId;

  CellLocation.fromJson(Map json) : _rowId = json['rowId'], _colId = json['colId'];
  Map toJson() => { 'rowId': _rowId, 'colId': _colId};
}
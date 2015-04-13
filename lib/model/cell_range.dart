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
 * Represents the immutable cell range in the spreadsheet.
 * Note: Range must contain at least 1 cell.
 */
class CellRange {
  CellLocation _startLocation;
  CellLocation get startLocation => _startLocation;

  CellLocation _endLocation;
  CellLocation get endLocation => _endLocation == null ? _startLocation : _endLocation;

  int get rowsCount => (endLocation.rowId - startLocation.rowId).abs() + 1;
  int get colsCount => (endLocation.colId - startLocation.colId).abs() + 1;
  int get cellsCount => rowsCount * colsCount;
    
  CellRange.all(Spreadsheet spreadsheet) : this(0,0, spreadsheet.colsCount - 1, spreadsheet.rowsCount - 1);
  CellRange.oneCell(int colId, int rowId) : this(colId, rowId);
  CellRange.row(int row, {int start: 0, int end: -1}) : this(start, row, end, row);
  CellRange.column(int col, {int start: 0, int end: -1}) : this(col, start, col, end);
  
  
  CellRange(int startColId, int startRowId, [int endColId = -1, int endRowId = -1]) {
    if(startRowId < 0 || startColId < 0) {
      throw new StateError("StartRowId and StartColId must be greater or equal to 0!");
    }

    _startLocation = new CellLocation(startColId, startRowId);

    if(endRowId >= 0 && endColId >= 0) {
      _endLocation = new CellLocation(endColId, endRowId);
    }
  }

  /**
   * Normalizes the [startLocation] and [endLocation] so the represents top left cell and the second
   * represents bottom right cell.
   */
  void normalize() {
    // TODO start location must be top left corner and end location must be right bottom corner
    throw new UnimplementedError();
  }
}
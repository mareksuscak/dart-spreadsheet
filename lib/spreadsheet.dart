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
library spreadsheet;

import 'dart:html';
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

import 'helpers/functions.dart';
import 'editors/editors.dart';
import 'renderers/renderers.dart';
import 'model/model.dart';

typedef void ConfigureColumnFunction(int colId, Column column);
typedef void ConfigureCellFunction(int rowId, int colId, Cell cell);
typedef void ConfigureRowFunction(int rowId, Row row);
typedef void PerformBulkUpdateFunction();

@CustomTag('x-spreadsheet')
class Spreadsheet extends PolymerElement {

  static final Logger _logger = new Logger('Spreadsheet');

  static int instancesCount = 0;
  bool _isActive = false;
  bool _isRendered = false;
  bool _isInitialized = false;
  bool _isDuplicationMode = false;

  /// Rows count, can be set just from the DOM attribute
  @published int rowsCount = 50;

  /// Columns count, can be set just from the DOM attribute
  @published int colsCount = 26;

  /// Frozen columns count, can be set just from the DOM attribute
  @published int frozenColsLeft = 0;

  /// Frozen rows count, can be set just from the DOM attribute
  @published int frozenRowsTop = 0;

  bool get freezebarVerticalVisible => frozenColsLeft > 0;
  bool get freezebarHorizontalVisible => frozenRowsTop > 0;

  int _overallWidth = 0;
  int _overallHeight = 0;

  int _scrollbarWidth = 0;
  bool _scrollbarOverlayed = false;

  int _contentWidth = 0;
  int _contentHeight = 0;

  int _fixedPartWidth = 0;
  int _fixedPartHeight = 0;

  int _scrollablePartWidth = 0;
  int _scrollablePartHeight = 0;

  int selectedColId = -1;
  int selectedRowId = -1;

  bool get isCellSelected => selectedColId >= 0 && selectedColId < colsCount && selectedRowId >= 0 && selectedRowId < rowsCount;
  Column get selectedCol => _columns[selectedColId];
  Row get selectedRow => _rows[selectedRowId];
  Cell get selectedCell => isCellSelected ? cells[selectedRowId][selectedColId] : null;

  ColumnCollection _columns = new ColumnCollection();
  Iterable<Column> get _columnsLeft => _columns.take(frozenColsLeft);
  Iterable<Column> get _columnsRight => _columns.skip(frozenColsLeft);

  RowCollection _rows = new RowCollection();
  Iterable<Row> get _rowsTop => _rows.take(frozenRowsTop);
  Iterable<Row> get _rowsBottom => _rows.skip(frozenRowsTop);

  /// There's only one instance of the editor per spreadsheet so we need to store their references.
  Map<Symbol, CellEditor> _editors = new Map<Symbol, CellEditor>();
  CellEditor get selectedCellEditor => selectedCell==null?null:_editors[selectedCell.editorName];
  bool get isSelectedCellEditorActive => selectedCellEditor==null?false:selectedCellEditor.isActive;

  /// There's only once instance of the renderer per spreadsheet so we need to store their references.
  Map<Symbol, CellRenderer> _renderers = new Map<Symbol, CellRenderer>();

  /// Storage of cell configuration along with its value
  CellCollection cells = new CellCollection();

  /// Container with fixed scrollbar that is used to measure scrollbar width.
  Element get _scrollbarMeasure => $['scrollbar-measure'];

  Element get _scrollContainer => $['scroll-container'];
  Element get _scrollContainerContent => $['scroll-container-content'];

  Element get _gridOuterContainer => $['grid-outer-container'];
  Element get _gridInnerContainer => $['grid-inner-container'];

  Element get _fixedOuterContainer => $['fixed-outer-container'];
  Element get _scrollableOuterContainer => $['scrollable-outer-container'];

  Element get _quadrantFixedLeft => $['quadrant-fixed-left'];
  Element get _quadrantFixedRight => $['quadrant-fixed-right'];

  Element get _quadrantScrollableLeft => $['quadrant-scrollable-left'];
  Element get _quadrantScrollableRight => $['quadrant-scrollable-right'];

  Element get _colgroupFixedLeft => $['colgroup-fixed-left'];
  Element get _colgroupFixedRight => $['colgroup-fixed-right'];

  Element get _colgroupScrollableLeft => $['colgroup-scrollable-left'];
  Element get _colgroupScrollableRight => $['colgroup-scrollable-right'];

  Element get _theadFixedLeft => $['thead-fixed-left'];
  Element get _theadFixedRight => $['thead-fixed-right'];

  Element get _headersRowFixedLeft => $['headers-row-fixed-left'];
  Element get _headersRowFixedRight => $['headers-row-fixed-right'];

  Element get _freezebarRowFixedLeft => $['freezebar-row-fixed-left'];
  Element get _freezebarRowFixedRight => $['freezebar-row-fixed-right'];

  Element get _tbodyFixedLeft => $['tbody-fixed-left'];
  Element get _tbodyFixedRight => $['tbody-fixed-right'];

  Element get _tbodyScrollableLeft => $['tbody-scrollable-left'];
  Element get _tbodyScrollableRight => $['tbody-scrollable-right'];

  Element get _rowHeadersBackground => $['row-headers-background'];
  Element get _columnHeadersBackground => $['column-headers-background'];

  Element get _selectedRowHeadersBackground => $['selected-row-headers-background'];
  Element get _selectedColumnHeadersBackground => $['selected-column-headers-background'];

  Element get _horizontalScrollbarShim => $['horizontal-scrollbar-shim'];
  Element get _horizontalScrollbarExtension => $['horizontal-scrollbar-extension'];
  Element get _verticalScrollbarShim => $['vertical-scrollbar-shim'];
  Element get _verticalScrollbarExtension => $['vertical-scrollbar-extension'];

  Element get _freezebarVertical => $['freezebar-vertical'];
  Element get _freezebarVerticalHandle => $['freezebar-vertical-handle'];
  Element get _freezebarVerticalHandleBar => $['freezebar-vertical-handle-bar'];
  Element get _freezebarVerticalDrop => $['freezebar-vertical-drop'];
  Element get _freezebarVerticalDropBar => $['freezebar-vertical-drop-bar'];

  Element get _freezebarHorizontal => $['freezebar-horizontal'];
  Element get _freezebarHorizontalHandle => $['freezebar-horizontal-handle'];
  Element get _freezebarHorizontalHandleBar => $['freezebar-horizontal-handle-bar'];
  Element get _freezebarHorizontalDrop => $['freezebar-horizontal-drop'];
  Element get _freezebarHorizontalDropBar => $['freezebar-horizontal-drop-bar'];

  Element get _editorContainer => $['editor-container'];
  Element get _editorContainerDecorator => $['editor-container-decorator'];

  Element get _overlayFixedLeft => $['overlay-fixed-left'];
  Element get _overlayFixedRight => $['overlay-fixed-right'];
  Element get _overlayScrollableLeft => $['overlay-scrollable-left'];
  Element get _overlayScrollableRight => $['overlay-scrollable-right'];

  StreamSubscription keydownSubscription;
  StreamSubscription keyupSubscription;
  StreamSubscription keypressedSubscription;
  StreamSubscription clickSubscription;
  StreamSubscription doubleClickSubscription;

  factory Spreadsheet() => new Element.tag('x-spreadsheet');
  Spreadsheet.created() : super.created() {
    // register default editors and renderers
    registerEditor(#text, new TextCellEditor());
    registerRenderer(#text, new TextCellRenderer());
  }

  /// Executed as soon as the element is prepared and published properties have their values
  /// propagated from the HTML document.
  @override
  void ready() {
    super.ready();
  }

  /// Executed as soon as this element is attached to the document, but
  /// siblings, ancestors and descendants cannot be accessed yet (distributed nodes?).
  @override
  void attached() {
    super.attached();

    if(instancesCount > 0) {
      _logger.severe("Two Spreadsheet instances cannot live together side by side because of conflicting shortcuts. Re-use the existing one or detach one from the DOM before attaching the other.");
      return;
    }

    // register cell event listeners
    clickSubscription = _gridInnerContainer.onClick.matches("td").listen(selectCellAction);
    doubleClickSubscription = _gridInnerContainer.onDoubleClick.matches("td").listen(activateCellAction);
    keypressedSubscription = document.onKeyPress.listen(keyPressedAction);
    keyupSubscription = document.onKeyUp.listen(keyUpAction);
    keydownSubscription = document.onKeyDown.listen(keyDownAction);

    // pause temporarily as we use it only for debouncing held keys
    keyupSubscription.pause();

    instancesCount++;
    _isActive = true;
  }

  /// Executed as soon as this element is attached to the document,
  /// published properties change handlers have been executed and descendants,
  /// siblings and ancestors can be accessed.
  @override
  void domReady() {
    super.domReady();
  }

  /// Executed as soon as this element is detached from the document.
  @override
  void detached() {
    super.detached();

    if(!_isActive) {
      return;
    }

    // cancel event listeners
    if(keypressedSubscription != null) {
      keypressedSubscription.cancel();
    }

    if(clickSubscription != null) {
      clickSubscription.cancel();
    }

    if(doubleClickSubscription != null) {
      doubleClickSubscription.cancel();
    }

    if(keyupSubscription != null) {
      keyupSubscription.cancel();
    }

    if(keydownSubscription != null) {
      keydownSubscription.cancel();
    }

    instancesCount--;
    _isActive = false;
  }

  /**************************/
  /* API                    */
  /**************************/

  /// Performs bulk update by removing inner container from document first and inserting it later.
  /// In firefox causes 6x faster rendering. In chrome 2x.
  void performBulkUpdate(PerformBulkUpdateFunction performBulkUpdateFunction) {
    var insertFunction = removeToInsertLater(_gridInnerContainer);
    performBulkUpdateFunction();
    insertFunction();
  }
  
  /// Runs the configuration on columns range starting at [startColId] up until [endColId].
  void configureColumns(int startColId, int endColId, ConfigureColumnFunction interceptor) {
    for (int i = startColId; i <= endColId; i++) {
      interceptor(i, _columns[i]);
    }

    _adjustScrollablePartWidth();

    if (startColId <= frozenColsLeft) {
      _adjustFixedPartWidth();
    }
  }

  /// Runs the configuration on rows from the [range].
  void configureRows(int startRowId, int endRowId, ConfigureRowFunction interceptor) {
    for (int i = startRowId; i <= endRowId; i++) {
      interceptor(i, _rows[i]);
    }

    _adjustScrollablePartHeight();

    if (startRowId <= frozenRowsTop) {
      _adjustFixedPartHeight();
    }
  }

  /// Runs the configuration on cells at [location].
  /// [location] can be of type Location or Range.
  void configureCells(CellRange range, ConfigureCellFunction interceptor) {
    for (int col = range.startLocation.colId; col <= range.endLocation.colId; col++) {
      for (int row = range.startLocation.rowId; row <= range.endLocation.rowId; row++) {
        interceptor(row, col, cells[row][col]);
      }
    }

    var updateUi = false;
    for (int row = range.startLocation.rowId; row <= range.endLocation.rowId; row++) {
      if(_adjustRowHeight(_rows[row]) != 0) {
        updateUi = true;
      }
    }

    if(updateUi) {
      _adjustScrollablePartHeight();

      if(selectedRowId <= frozenRowsTop) {
        _adjustFixedPartHeight();
      }
    }
  }

  /// Inserts data at specified position.
  /// [data] can be of any type (e.g. List, Map, child inherited from Object).
  /// Algorithm starts the insertion at [rowId] and [colId] coordinates.
  ///
  /// This function does not adjust row height if single value is too big for cell's size.
  /// For that purpose call [Spreadsheet.adjustRowHeight] passing [rowId].
  void insertDataAt(int colId, int rowId, Object data, {bool vertical: false}) {
    if (data is List) {
      if (vertical) {
        if (rowId + data.length > rowsCount) {
          throw new StateError("Table is not big enough, add some rows first.");
        }

        var countTo = rowId + data.length;
        for (int i = rowId,
            j = 0; i < countTo; i++, j++) {
          setCellValueAt(colId, i, data[j]);
        }
      } else {
        if (colId + data.length > colsCount) {
          throw new StateError("Table is not big enough, add some columns first.");
        }

        var countTo = colId + data.length;
        for (int i = colId,
            j = 0; i < countTo; i++, j++) {
          setCellValueAt(i, rowId, data[j]);
        }
      }
    } else if (data is Map) {
      throw new StateError("Map insertion is not implemented yet.");
    } else /* Object */ {
      setCellValueAt(colId, rowId, data);
    }
  }


  /// Clears the data from spreadsheet. If [range] is passed,
  /// clears only the data within the range.
  void clear([CellRange range = null]) {
    if (range == null) {
      for (int i = 0; i < rowsCount; i++) {
        for (int j = 0; j < colsCount; j++) {
          setCellValueAt(j, i, null);
        }
      }
    } else {
      for (int i = range.startLocation.rowId; i <= range.endLocation.rowId; i++) {
        for (int j = range.startLocation.colId; j <= range.endLocation.colId; j++) {
          setCellValueAt(j, i, null);
        }
      }
    }
  }

  /// Renders the spreadsheet contents.
  /// Internally calls syncRender inside an async future.
  /// This function automatically resets contents to the default values preserving just published properties.
  /// Note: This function is idempotent meaning that it can be called multiple times without any side effects.
  /// Note: This function takes pretty much time so consider it when calling multiple times.
  Future render() {
    return new Future(() {
      syncRender();
    });
  }


  /// Blocking version of render method
  void syncRender() {
    _gridOuterContainer.hidden = true;
    _render();
    _gridOuterContainer.hidden = false;
  }


  /// Pushes new [value] to the cell located at [rowId] and [colId] coord.
  /// use the 'cells[row][col].value instead of this method
  @deprecated 
  void setCellValueAt(int colId, int rowId, Object value) {
    if (rowId < 0 || rowId >= rowsCount || colId < 0 || colId >= colsCount) {
      throw new StateError("Requested cell is outside the table boundary (row: ${rowId}; col: ${colId})");
    }

    cells[rowId][colId].value = value;
  }

  /// Registers custom cell [editor] under specified [name].
  void registerEditor(Symbol name, CellEditor editor) {
    if (_editors.containsKey(name)) {
      throw new StateError("Editor with the same name is already registered.");
    }

    _editors[name] = editor;
  }

  /// Registers custom cell [renderer] under specified [name].
  void registerRenderer(Symbol name, CellRenderer renderer) {
    if (_renderers.containsKey(name)) {
      throw new StateError("Renderer with the same name is already registered.");
    }

    _renderers[name] = renderer;
  }

  /**************************/
  /* Event handlers         */
  /**************************/

  /// Handles mouse wheel scroll event and scrolls the appropriate tables.
  void mouseWheelAction(WheelEvent event, Object detail, EventTarget sender) {
    // here we MUST use e.target instead of the sender
    Element element = event.target as Element;

    // scroll container is handled in a different handler as we can use it by scrollbar dragging as well
    if (element.id != "scroll-container") {

      int deltaX = event.deltaX.truncate();
      int deltaY = event.deltaY.truncate();

      // fucking firefox uses reversed logic..
      if (event.type == "DOMMouseScroll") {
        deltaX = -deltaX;
        deltaY = -deltaY;
      }

      switch (event.deltaMode) {
        case WheelEvent.DOM_DELTA_LINE:
          _scrollContainer.scrollByLines(deltaY);
          break;

        case WheelEvent.DOM_DELTA_PAGE:
          _scrollContainer.scrollByPages(deltaY);
          break;

        case WheelEvent.DOM_DELTA_PIXEL:
          _scrollContainer.scrollLeft += deltaX;
          _scrollContainer.scrollTop += deltaY;
          break;
      }

      _ensureEditorDecoratorVisible();

      event.preventDefault();
    }
  }


  /// Handles scroll event on the scrollable container and scrolls the appropriate tables.
  void scrollTableAction(Event event, Object detail, EventTarget sender) {
    Element element = event.target as Element;

    _scrollHorizontal(element.scrollLeft, WheelEvent.DOM_DELTA_PIXEL, relative: false);
    _scrollVertical(element.scrollTop, WheelEvent.DOM_DELTA_PIXEL, relative: false);

    _ensureEditorDecoratorVisible();
  }


  /// Prevents text selection on cell's double click event.
  /// NOTE: This is a workaround of user-select CSS attribute just to make sure it works
  /// cross-legacy-browser.
  void preventTextSelectionAction(Event event, Object detail, EventTarget sender) {
    event.preventDefault();
  }


  /// Handles page down keyboard shortcut event.
  void pageDownScrollAction(Event event) {
    _scrollVertical(51, WheelEvent.DOM_DELTA_PIXEL, relative: true);
    _scrollContainer.scrollTop += 51;
    event.preventDefault();
  }


  /// Handles page up keyboard shortcut event.
  void pageUpScrollAction(Event event) {
    _scrollVertical(-51, WheelEvent.DOM_DELTA_PIXEL, relative: true);
    _scrollContainer.scrollTop -= 51;
    event.preventDefault();
  }

  /// Handles key down event
  void keyDownAction(KeyboardEvent event) {    
    //TODO: handle keyCode 13 as 'shiftEnterAction' when https://code.google.com/p/chromium/issues/detail?id=380690 gets fixed
    if (event.keyCode == 33) {
      pageUpScrollAction(event);
    } else if (event.keyCode == 34) {
      pageDownScrollAction(event);
    }  else if (event.keyCode == 8 || event.keyCode == 46) {
      deleteAction(event);
    } else if (event.keyCode == 27) {
      escapeAction(event);
    } else if (event.keyCode ==  13) {
      enterAction(event);
    } else if (event.keyCode == 9) {
      if (event.shiftKey) {
        shiftTabAction(event);
      } else {
        tabAction(event);  
      }      
    } else if (event.keyCode == 37) {
      moveLeftAction(event);      
    } else if (event.keyCode == 38) {
      moveUpAction(event);
    } else if (event.keyCode == 39) {
      moveRightAction(event);
    } else if (event.keyCode == 40) {
      moveDownAction(event);
    }
    
    //When SHIFT+ALT are pressed together and we are not yet in duplication mode
    if(event.altKey && event.shiftKey && !_isDuplicationMode) {
      _isDuplicationMode = true;
      keydownSubscription.pause();
      keyupSubscription.resume();
      _updateActiveCellBorderCssClass();
    }
  }

  /// Handles key up event
  void keyUpAction(KeyboardEvent event) {
    
    //arrows handling
    if (event.keyCode == 37) {
      moveLeftAction(event);      
    } else if (event.keyCode == 38) {
      moveUpAction(event);
    } else if (event.keyCode == 39) {
      moveRightAction(event);
    } else if (event.keyCode == 40) {
      moveDownAction(event);
    }

    // When one of keys from SHIFT+ALT combination is released and we are in duplication mode
    if((!event.altKey || !event.shiftKey) && _isDuplicationMode) {
      _isDuplicationMode = false;

      keydownSubscription.resume();
      keyupSubscription.pause();

      _updateActiveCellBorderCssClass();
    }
  }

  /// Handles key press event that activated cell editor when character key is pressed.
  void keyPressedAction(KeyboardEvent event) {
    if( event.keyCode == 10 ||
        event.ctrlKey ||
        event.altKey ||
        event.metaKey ||
        !isCellSelected ||
        (isCellSelected && isSelectedCellEditorActive)) {
      return;
    }
    
    // Firefox emits keypress event also for non character keys so we have to check for charcode
    // Internet Explorer emits this event for ESC button with a charcode
    if(event.charCode <= 0 || event.charCode == 27) {
      return;
    }

    // Chrome
    if(event.keyCode == KeyCode.ENTER) {
      event.preventDefault();
      return;
    }

    activateCell(new String.fromCharCode(event.charCode));

    // Important to prevent chrome from appending a character twice.
    event.preventDefault();
  }

  void _ensureElementVisibility(Element element) {
    var quadrant = _getSelectedCellQuadrant();

    if (quadrant.q0) {
      return;
    }

    var offsetLeft = element.offsetLeft;
    var offsetTop = element.offsetTop;
    var offsetRight = offsetLeft + element.borderEdge.width - 1; // -1 means we want to scroll exactly to the right cell border
    var offsetBottom = offsetTop + element.borderEdge.height - 1; // -1 means we want to scroll exactly to the bottom cell border
    var scrollLeft = _scrollContainer.scrollLeft;
    var scrollTop = _scrollContainer.scrollTop;
    var scrollRight = scrollLeft;
    var scrollBottom = scrollTop;

    if(quadrant.right) {
      scrollRight += _contentWidth - _fixedPartWidth;
    }

    if(quadrant.bottom) {
      scrollBottom += _contentHeight - _fixedPartHeight;
    }

    if(quadrant.q3 || quadrant.q1) {
      if(offsetLeft < scrollLeft) {
        var toScroll = offsetLeft - scrollLeft;
        _scrollHorizontal(toScroll, WheelEvent.DOM_DELTA_PIXEL, relative: true);
        _scrollContainer.scrollLeft += toScroll;
      } else if(offsetRight > scrollRight) {
        var toScroll =  offsetRight - scrollRight;
        _scrollHorizontal(toScroll, WheelEvent.DOM_DELTA_PIXEL, relative: true);
        _scrollContainer.scrollLeft += toScroll;
      }
    }

    if(quadrant.q3 || quadrant.q2) {
      if(offsetTop < scrollTop) {
        var toScroll = offsetTop - scrollTop;
        _scrollVertical(toScroll, WheelEvent.DOM_DELTA_PIXEL, relative: true);
        _scrollContainer.scrollTop += toScroll;
      } else if(offsetBottom > scrollBottom) {
        var toScroll =  offsetBottom - scrollBottom;
        _scrollVertical(toScroll, WheelEvent.DOM_DELTA_PIXEL, relative: true);
        _scrollContainer.scrollTop += toScroll;
      }
    }
  }

  /// Adjusts row height and optionally also adjusts a layout for new row's height.
  /// Please note that adjusting layout can be inefficient if called often and  that's why
  /// this function provides [adjustLayout].
  void adjustRowHeight(int rowId, {bool adjustLayout: false}) {
    var updateUi = _adjustRowHeight(_rows[rowId]) != 0 ? true : false;

    if(adjustLayout && offset != 0) {
      _adjustScrollablePartHeight();

      if(rowId <= frozenRowsTop) {
        _adjustFixedPartHeight();
      }
    }
  }

  int _adjustRowHeight(Row row) {
    row.trElements.forEach((e) => e.style.height = "auto");

    var preservedHeight = row.preservedMinimumHeight;
    var maxHeight = preservedHeight;
    for(Element tr in row.trElements) {
      if(tr.clientHeight > maxHeight) {
        maxHeight = tr.clientHeight;
      }
    }
    var offset = maxHeight - row.height;
    row.height = maxHeight;

    // Reset preservedMinimumHeight to its default value
    // after setting row.height which changes its value as well
    row.preservedMinimumHeight = preservedHeight;

    return offset;
  }

  void _adjustFixedPartHeight() {
    _calculateFixedPartHeight();

    _updateFixedOuterContainer();
    _updateScrollableOuterContainer();
    _updateScrollContainer();
    _updateScrollContainerContent();
    _updateHorizontalScrollbarExtension();
    _updateFreezebarHorizontal();
    _updateQuadrantFixedLeft();
    _updateQuadrantFixedRight();
    _updateQuadrantScrollableLeft();
    _updateQuadrantScrollableRight();
  }

  void _adjustScrollablePartHeight() {
    _calculateScrollablePartHeight();

    _updateScrollContainerContent();
  }

  void _adjustScrollablePartWidth() {
    _calculateScrollablePartWidth();

    _updateScrollContainerContent();
  }

  void _adjustFixedPartWidth() {
      _calculateFixedPartWidth();

      _updateFixedOuterContainer();
      _updateScrollableOuterContainer();
      _updateScrollContainer();
      _updateScrollContainerContent();
      _updateVerticalScrollbarExtension();
      _updateFreezebarVertical();
      _updateQuadrantFixedLeft();
      _updateQuadrantFixedRight();
      _updateQuadrantScrollableLeft();
      _updateQuadrantScrollableRight();
  }

  void duplicateCell(int sourceColId, int sourceRowId, int destinationColId, int destinationRowId) {
    if(cells[destinationRowId][destinationColId].readonly) {
      return;
    }

    _editComplete(destinationColId, destinationRowId, cells[sourceRowId][sourceColId].value);
  }

  /// Selects cell at [colId] and [rowId] position.
  void selectCell(int colId, int rowId) {
    // if there's open cell editor, just explicitly trigger complete action
    if(selectedCellEditor != null && isSelectedCellEditorActive) {
      _editComplete(selectedColId, selectedRowId, selectedCellEditor.pullValue());
      selectedCellEditor.deactivate();
    }

    // set selected coordinates
    selectedColId = colId;
    selectedRowId = rowId;

    var td = cells[selectedRowId][selectedColId].element;

    // ensure that cell is visible in current viewport
    _ensureElementVisibility(td);

    // bring the selection rectangle to the proper position
    _updateActiveCellBorders(true, td.offsetLeft, td.offsetTop, td.borderEdge.width, td.borderEdge.height);
    _updateActiveCellBorderCssClass();    
    _updateActiveRowCssClass(rowId);

    // fire an event
    asyncFire("cell-selected", detail: {
      'value': selectedCell.value,
      'colId': selectedColId,
      'rowId': selectedRowId
    });
  }

  /// Deselects selected cell.
  void deselectCell() {
    if(!isCellSelected) {
      return;
    }

    // to be sure deactivate cell first
    deactivateCell();

    // This has to be called before we reset selectedColId and selectedRowId
    _updateActiveCellBorders(false);

    selectedColId = -1;
    selectedRowId = -1;
  }

  /// Activates currently selected cell optionally pushing [initialValue] to the cell.
  void activateCell([String initialValue = null]) {
    if (isCellSelected && !selectedCell.readonly) {
      var td = cells[selectedRowId][selectedColId].element;
      var editor = _ensureCellEditor(selectedCell.editorName);
      var editorElement = editor as Element;

      editor.pushValue(initialValue == null ? selectedCell.value : initialValue);
      editor.activate();

      var top = td.offsetTop - 1;
      var left = td.offsetLeft - 1;

      if (selectedColId >= frozenColsLeft) {
        left += _fixedPartWidth - _scrollContainer.scrollLeft;
      }

      if (selectedRowId >= frozenRowsTop) {
        top += _fixedPartHeight - _scrollContainer.scrollTop;
      }

      var cellComputedStyle = selectedCell.element.getComputedStyle();

      _editorContainer.hidden = false;
      _editorContainer.style
          ..top = "${top}px"
          ..left = "${left}px"
          ..minWidth = "${selectedCol.width-3}px"
          ..minHeight = "${selectedRow.height-3}px"
          ..height = "auto"
          ..width = "auto"
          ..fontSize = cellComputedStyle.fontSize
          ..fontFamily = cellComputedStyle.fontFamily
          ..maxWidth = "${_contentWidth - left - 4}px"
          ..textAlign = cellComputedStyle.textAlign
          ..maxHeight = "${_contentHeight - top - 4}px";
    }
  }

  /// Deactivated activated cell.
  void deactivateCell() {
    if(selectedCellEditor==null) {
      return;
    }

    selectedCellEditor.deactivate();
    _editorContainer.hidden = true;
    _editorContainerDecorator.hidden = true;
  }

  /// Handles cell single click event.
  void selectCellAction(Event event) {
    // here we MUST use e.target instead of the sender
    TableCellElement td = event.matchingTarget as TableCellElement;
    TableRowElement tr = td.parent as TableRowElement;

    // select just if it was table data or header cell
    if (!td.attributes.containsKey("colId")) {
      return;
    }

    int rowId = int.parse(tr.attributes['rowId']);
    int colId = int.parse(td.attributes['colId']);

    selectCell(colId, rowId);
  }


  /// Handles cell double click event.
  void activateCellAction(Event event) {
    // here we MUST use e.target instead of the sender
    TableCellElement td = event.matchingTarget as TableCellElement;
    TableRowElement tr = td.parent as TableRowElement;

    // Note: We do not need event's target here as selected handler already set selection coordinates
    activateCell();
  }

  void _editComplete(int colId, int rowId, Object value) {
    deactivateCell();

    var event = fire("cell-changed", detail: {
        'value': value,
        'colId': colId,
        'rowId': rowId
    });

    if(!event.defaultPrevented) {
      cells[rowId][colId].value = value;
    }

    adjustRowHeight(rowId, adjustLayout: true);
  }

  /// Handles edit complete event from cell editor.
  void editCompleteAction(Event event, Object detail) {
    _editComplete(selectedColId, selectedRowId, detail);

    // Select again in case that line height has changed
    selectCell(selectedColId, selectedRowId);
  }

  /// Moves selection upwards.
  void moveUp() {
    if(selectedRowId > 0 && !isSelectedCellEditorActive) {
      if(_isDuplicationMode) {
        duplicateCell(selectedColId, selectedRowId, selectedColId, selectedRowId - 1);
      }

      selectCell(selectedColId, selectedRowId-1);
    }
  }

  /// Moves selection to the right.
  void moveRight() {
    if(selectedColId >= 0 && selectedColId < colsCount-1 && !isSelectedCellEditorActive) {
      if(_isDuplicationMode) {
        duplicateCell(selectedColId, selectedRowId, selectedColId + 1, selectedRowId);
      }

      selectCell(selectedColId+1, selectedRowId);
    }
  }

  /// Moves selection downwards.
  void moveDown() {
    if(selectedRowId >= 0 && selectedRowId < rowsCount-1 && !isSelectedCellEditorActive) {
      if(_isDuplicationMode) {
        duplicateCell(selectedColId, selectedRowId, selectedColId, selectedRowId + 1);
      }

      selectCell(selectedColId, selectedRowId+1);
    }
  }

  /// Moves selection to the left.
  void moveLeft() {
    if(selectedColId > 0 && !isSelectedCellEditorActive) {
      if(_isDuplicationMode) {
        duplicateCell(selectedColId, selectedRowId, selectedColId-1, selectedRowId);
      }

      selectCell(selectedColId-1, selectedRowId);
    }
  }


  /// Handles up arrow keyboard shortcut.
  void moveUpAction(Event event) {
    if(isCellSelected && isSelectedCellEditorActive) {
      return;
    }

    moveUp();
    event.preventDefault();
  }


  /// Handles right arrow keyboard shortcut.
  void moveRightAction(Event event) {
    if(isCellSelected && isSelectedCellEditorActive) {
      return;
    }

    moveRight();
    event.preventDefault();
  }


  /// Handles down arrow keyboard shortcut.
  void moveDownAction(Event event) {
    if(isCellSelected && isSelectedCellEditorActive) {
      return;
    }

    moveDown();
    event.preventDefault();
  }


  /// Handles left arrow keyboard shortcut.
  void moveLeftAction(Event event) {
    if(isCellSelected && isSelectedCellEditorActive) {
      return;
    }

    moveLeft();
    event.preventDefault();
  }


  /// Handles delete shortcut.
  void deleteAction(Event event) {
    if (isCellSelected && !isSelectedCellEditorActive && !selectedCell.readonly) {
      _editComplete(selectedColId, selectedRowId, "");
    }
  }


  /// Handles escape shortcut.
  void escapeAction(Event event) {
    if(selectedCellEditor != null && isSelectedCellEditorActive) {
      deactivateCell();

      // If decorator has been shown, selection borders have been hidden so show them again
      selectCell(selectedColId, selectedRowId);
    } else {
      deselectCell();
    }
  }

  /// Handles enter shortcut.
  void enterAction(Event event) {
    if(isCellSelected && !isSelectedCellEditorActive) {
      activateCell();
    } else if(isCellSelected && isSelectedCellEditorActive) {
      _editComplete(selectedColId, selectedRowId, selectedCellEditor.pullValue());
      selectedCellEditor.deactivate();
      moveDown();
    }
  }


  /// Handles shift+enter shortcut.
  void shiftEnterAction(Event event) {
    if(isCellSelected && !isSelectedCellEditorActive) {
      activateCell();
    } else if(isCellSelected && isSelectedCellEditorActive) {
      _editComplete(selectedColId, selectedRowId, selectedCellEditor.pullValue());
      selectedCellEditor.deactivate();
      moveUp();
    }
  }


  /// Handles tab shortcut.
  void tabAction(Event event) {
    if(isCellSelected && isSelectedCellEditorActive) {
      _editComplete(selectedColId, selectedRowId, selectedCellEditor.pullValue());
      selectedCellEditor.deactivate();
    }

    if(isCellSelected) {
      event.preventDefault();
    }

    moveRight();
  }


  /// Handles shift+tab shortcut.
  void shiftTabAction(Event event) {
    if(isCellSelected && isSelectedCellEditorActive) {
      _editComplete(selectedColId, selectedRowId, selectedCellEditor.pullValue());
      selectedCellEditor.deactivate();
    }

    if(isCellSelected) {
      event.preventDefault();
    }

    moveLeft();
  }


  /**************************/
  /* Private                */
  /**************************/

  Quadrant _getSelectedCellQuadrant() {
    var left = selectedColId < frozenColsLeft;
    var top = selectedRowId < frozenRowsTop;    

    return new Quadrant(left, top);
  }

  Element _getOverlayContainerForSelectedCell() {
    if (!isCellSelected) {
      throw new StateError("No cell is selected.");
    }

    var quadrant = _getSelectedCellQuadrant();

    if (quadrant.q0) {
      return _overlayFixedLeft;
    } else if (quadrant.q2) {
      return _overlayScrollableLeft;
    } else if (quadrant.q1) {
      return _overlayFixedRight;
    } else {
      return _overlayScrollableRight;
    }
  }

  void _ensureRendered() {
    if (!_isRendered) {
      throw new StateError("You must called render() method before trying to change contents of the Spreadsheet.");
    }
  }

  void _addRows([int count = 1]) {
    var defaultRenderer = _renderers[#text];

    for (int i = 0; i < count; i++) {
      _rows.add(new Row());
      cells.add(new List<Cell>());

      for (int j = 0; j < colsCount; j++) {
        var cell = new Cell(defaultRenderer);
        cells[i].add(cell);
      }
    }
  }

  void _addColumns([int count = 1]) {
    var defaultRenderer = _renderers[#text];

    for (int i = 0; i < count; i++) {
      _columns.add(new Column());
    }

    for (int i = 0; i < rowsCount; i++) {
      for (int j = 0; j < count; j++) {
        var cell = new Cell(defaultRenderer);
        cells[i].add(cell);
      }
    }
  }

  void _calculateScrollbarWidth() {
    // NOTE: Mac OS X by default does not have a scrollbar displayed so we have to set minimum scrollbar size
    int calculatedScrollbarWidth = _scrollbarMeasure.offsetWidth - _scrollbarMeasure.clientWidth;

    // On Mac OS X scrollbar behaves differently - it is displayed as an overlay over the content
    _scrollbarOverlayed = (calculatedScrollbarWidth == 0);
    _scrollbarWidth = _scrollbarOverlayed ? 15 : calculatedScrollbarWidth;
  }

  void _calculateContainerProportions() {
    // Get content view dimensions
    _overallWidth = contentEdge.width;
    _overallHeight = contentEdge.height;
  }

  void _reset() {
    // first clear objects
    Stopwatch sw = new Stopwatch()..start();

    // deselect cell if selected
    if(isCellSelected) {
      deselectCell();
    }

    _rows.clear();
    _columns.clear();
    cells.clear();

    // and fill them up
    _addRows(rowsCount);
    _addColumns(colsCount);

    _logger.info("Re-creation of the columns and rows collection took ${sw.elapsedMilliseconds}ms");
    sw.reset();

    // remove all elements that are marked as generated
    _gridInnerContainer.querySelectorAll(".gen").forEach((e) => e.remove());

    _logger.info("Query selector and deletion of all generated nodes took ${sw.elapsedMilliseconds}ms");
    sw.stop();

    _isRendered = false;
  }

  void _render() {
    if (_isRendered || !_isInitialized) {
      _reset();
      _isInitialized = true;
    }

    Stopwatch sw = new Stopwatch()..start();

    // first calculate scrollbar width and content view proportions
    _calculateScrollbarWidth();
    _calculateContainerProportions();
    _calculateContentWidth();
    _calculateContentHeight();
    _calculateFixedPartWidth();
    _calculateFixedPartHeight();
    _calculateScrollablePartHeight();
    _calculateScrollablePartWidth();
    _calculateScrollablePartHeight();

    _logger.info("Initial calculations took ${sw.elapsedMilliseconds}ms");
    sw.reset();

    // update proportions of different container elements
    performBulkUpdate(() {
      _updateGridOuterContainer();
      _updateGridInnerContainer();
      _updateFixedOuterContainer();
      _updateQuadrantFixedLeft();
      _updateQuadrantFixedRight();
      _updateScrollableOuterContainer();
      _updateQuadrantScrollableLeft();
      _updateQuadrantScrollableRight();
      _updateScrollContainer();
      _updateScrollContainerContent();
      _updateScrollbarShims();
      _updateVerticalScrollbarExtension();
      _updateHorizontalScrollbarExtension();
      _updateFreezebarHorizontal();
      _updateFreezebarVertical();
      _updateColumnHeadersBackground();
      _updateRowHeadersBackground();
      _updateOverlays();

      _logger.info("Update core elements took ${sw.elapsedMilliseconds}ms");
      sw.reset();

      _renderNewColumnsAndFreezebar();
      _renderNewRows();
      
      _logger.info("Append new cell and freezebar elements took ${sw.elapsedMilliseconds}ms");
      sw.stop();
    });
    
    _isRendered = true;
  }

  void _renderNewColumnsAndFreezebar() {
    for (int i = 0; i < frozenColsLeft; i++) {
      // <col>
      var colElements = new List<TableColElement>();
      var colToInsert = new TableColElement();
      colToInsert.attributes["colId"] = "$i";
      colToInsert.classes.add("gen");

      var colToInsertClone = colToInsert.clone(true);
      colElements.addAll([colToInsert, colToInsertClone]);
      _columns[i].colElements = colElements;

      _colgroupFixedLeft.insertBefore(colToInsert, _colgroupFixedLeft.children.last);
      _colgroupScrollableLeft.insertBefore(colToInsertClone, _colgroupScrollableLeft.children.last);

      // <th> for column headers
      var thToInsert = new Element.th();
      thToInsert.appendText(toExcelColumnCode(i));
      thToInsert.classes.addAll(["gen", "header-cell"]);

      _headersRowFixedLeft.insertBefore(thToInsert, _headersRowFixedLeft.children.last);

      // <td> for freezebar
      var tdToInsert = new TableCellElement();
      tdToInsert.classes.addAll(["freezebar-cell", "freezebar-horizontal-cell"]);
      tdToInsert.classes.add("gen");

      _freezebarRowFixedLeft.insertBefore(tdToInsert, _freezebarRowFixedLeft.children.last);
    }

    for (int i = frozenColsLeft; i < colsCount; i++) {
      // <col>
      var colElements = new List<TableColElement>();
      var colToInsert = new TableColElement();
      colToInsert.attributes["colId"] = "${i}";
      colToInsert.classes.add("gen");

      var colToInsertClone = colToInsert.clone(true);
      colElements.addAll([colToInsert, colToInsertClone]);
      _columns[i].colElements = colElements;

      _colgroupFixedRight.append(colToInsert);
      _colgroupScrollableRight.append(colToInsertClone);

      // <th> for column headers
      var thToInsert = new Element.th();
      thToInsert.appendText(toExcelColumnCode(i));
      thToInsert.classes.addAll(["gen", "header-cell"]);

      _headersRowFixedRight.append(thToInsert);

      // <td> for freezebar
      var tdToInsert = new TableCellElement();
      tdToInsert.classes.addAll(["freezebar-cell", "freezebar-horizontal-cell"]);
      tdToInsert.classes.add("gen");

      _freezebarRowFixedRight.append(tdToInsert);
    }
  }

  void _renderNewRows() {
    for (int i = 0; i < rowsCount; i++) {
      _renderNewRow(i);
    }
  }

  void _renderNewRow(int index) {
    // rows for left and right quadrant
    var trElements = new List<TableRowElement>();
    var trLeftToInsert = new TableRowElement();
    trLeftToInsert.attributes['rowId'] = "${index}";
    trLeftToInsert.classes.addAll(["gen", "row"]);
    var trRightToInsert = trLeftToInsert.clone(true);

    trElements.addAll([trLeftToInsert, trRightToInsert]);
    _rows[index].trElements = trElements;

    // row header for left row
    var thToInsert = new Element.th();
    thToInsert.classes.addAll(["header-cell"]);
    thToInsert.appendText("${index+1}");
    trLeftToInsert.append(thToInsert);

    // cells for left row
    for (int j = 0; j < frozenColsLeft; j++) {
      var tdToInsert = _createTableCellElementFor(cells[index][j], index, j);
      trLeftToInsert.append(tdToInsert);
    }

    // freezebar cell for left row
    var freezebarCellToInsert = new TableCellElement();
    freezebarCellToInsert.classes.addAll(["freezebar-cell", "freezebar-vertical-cell"]);
    trLeftToInsert.append(freezebarCellToInsert);

    // cells for right row
    for (int j = frozenColsLeft; j < colsCount; j++) {
      var tdToInsert = _createTableCellElementFor(cells[index][j], index, j);
      trRightToInsert.append(tdToInsert);
    }

    // append rows
    if (index < frozenRowsTop) {
      _tbodyFixedLeft.insertBefore(trLeftToInsert, _tbodyFixedLeft.children.last);
      _tbodyFixedRight.insertBefore(trRightToInsert, _tbodyFixedRight.children.last);
    } else {
      _tbodyScrollableLeft.append(trLeftToInsert);
      _tbodyScrollableRight.append(trRightToInsert);
    }
  }

  TableCellElement _createTableCellElementFor(Cell cell, int rowId, int colId) {
    var height = _rows[rowId].height-1-4; // 4 includes padding + border
    var tdToInsert = new TableCellElement();
    tdToInsert.classes.add("data-cell");
    tdToInsert.attributes['colId'] = "${colId}";

    // Pass <td> element's reference
    cells[rowId][colId].element = tdToInsert;

    return tdToInsert;
  }

  CellEditor _ensureCellEditor(Symbol name) {
    CellEditor editor = _editors[name];
    Element editorElement = editor as Element;

    if (editorElement.parent == null) {
      _editorContainer.append(editorElement);
    }

    return editor;
  }

  void _ensureEditorDecoratorVisible() {
    if (!_editorContainer.hidden && _editorContainerDecorator.hidden) {
      _updateActiveCellBorders(false);

      if (_editorContainerDecorator.firstChild != null) {
        _editorContainerDecorator.firstChild.remove();
      }

      _editorContainerDecorator.appendText(toExcelCoord(selectedColId, selectedRowId));
      _editorContainerDecorator.hidden = false;
      _editorContainerDecorator.style
          ..top = "${_editorContainer.offsetTop - _editorContainerDecorator.borderEdge.height}px"
          ..left = "${_editorContainer.offsetLeft}px";
    }
  }

  void _scrollHorizontal(int position, int mode, {bool relative: false}) {
    if (relative) {
      switch (mode) {
        case WheelEvent.DOM_DELTA_PIXEL:
          _quadrantScrollableRight.scrollLeft += position;
          _quadrantFixedRight.scrollLeft += position;
          break;

        case WheelEvent.DOM_DELTA_LINE:
        case WheelEvent.DOM_DELTA_PAGE:
          throw new StateError("Relative horizontal positioning for LINE and PAGE mode is not supported.");
          break;
      }

    } else {
      switch (mode) {
        case WheelEvent.DOM_DELTA_PIXEL:
          _quadrantScrollableRight.scrollLeft = position;
          _quadrantFixedRight.scrollLeft = position;
          break;

        case WheelEvent.DOM_DELTA_LINE:
        case WheelEvent.DOM_DELTA_PAGE:
          throw new StateError("Absolute horizontal positioning for LINE and PAGE mode is not supported.");
          break;
      }
    }
  }

  void _scrollVertical(int position, int mode, {bool relative: false}) {
    if (relative) {
      switch (mode) {
        case WheelEvent.DOM_DELTA_PIXEL:
          _quadrantScrollableLeft.scrollTop += position;
          _quadrantScrollableRight.scrollTop += position;
          break;

        case WheelEvent.DOM_DELTA_LINE:
          _quadrantScrollableLeft.scrollByLines(position);
          _quadrantScrollableRight.scrollByLines(position);
          break;

        case WheelEvent.DOM_DELTA_PAGE:
          _quadrantScrollableLeft.scrollByPages(position);
          _quadrantScrollableRight.scrollByPages(position);
          break;
      }
    } else {
      switch (mode) {
        case WheelEvent.DOM_DELTA_PIXEL:
          _quadrantScrollableLeft.scrollTop = position;
          _quadrantScrollableRight.scrollTop = position;
          break;

        case WheelEvent.DOM_DELTA_LINE:
        case WheelEvent.DOM_DELTA_PAGE:
          throw new StateError("Absolute vertical positioning for LINE and PAGE mode is not supported.");
          break;
      }
    }
  }

  void _calculateContentWidth() {
    _contentWidth = _overallWidth - _scrollbarWidth - 1;
  }

  void _calculateContentHeight() {
    _contentHeight = _overallHeight - _scrollbarWidth - 1;
  }

  void _calculateFixedPartWidth() {
    int fixedPartWidth = 0;

    for (var col in _columnsLeft) {
      fixedPartWidth += col.width;
    }

    this._fixedPartWidth = fixedPartWidth + 46 + (freezebarVerticalVisible ? 4 : 0);
  }

  void _calculateFixedPartHeight() {
    int fixedPartHeight = 0;

    for (var row in _rowsTop) {
      fixedPartHeight += row.height;
    }

    this._fixedPartHeight = fixedPartHeight + 24 + (freezebarHorizontalVisible ? 4 : 0);
  }

  void _calculateScrollablePartWidth() {
    int scrollablePartWidth = 0;

    for (int i = frozenColsLeft; i < _columns.length; i++) {
      scrollablePartWidth += _columns[i].width;
    }

    this._scrollablePartWidth = scrollablePartWidth;
  }

  void _calculateScrollablePartHeight() {
    int scrollablePartHeight = 0;

    for (int i = frozenRowsTop; i < _rows.length; i++) {
      scrollablePartHeight += _rows[i].height;
    }

    this._scrollablePartHeight = scrollablePartHeight;
  }

  void _updateActiveCellBorderCssClass() {
    Element overlayContainer = _getOverlayContainerForSelectedCell();
    ElementList activeCellBorders = overlayContainer.querySelectorAll(".active-cell-border-container .range-border");

    if(_isDuplicationMode) {
      activeCellBorders.classes.remove("active-cell-border");
      activeCellBorders.classes.add("duplication-active-cell-border");
    } else {
      activeCellBorders.classes.add("active-cell-border");
      activeCellBorders.classes.remove("duplication-active-cell-border");
    }
  }

  void _updateActiveCellBorders(bool display, [int left = 0, int top = 0, int width = 0, int height = 0]) {
    Element overlayContainer = _getOverlayContainerForSelectedCell();
    Element activeCellBorderContainer = overlayContainer.querySelector(".active-cell-border-container");

    // hide all selection containers
    _gridInnerContainer.querySelectorAll(".active-cell-border-container").forEach((e) => e.hidden = true);

    // break if no cell is selected
    if (!isCellSelected) {
      return;
    }

    // set position of correct active cell border container
    activeCellBorderContainer.style
        ..top = "${top + (overlayContainer.offsetTop*-1)}px"
        ..left = "${left + (overlayContainer.offsetLeft*-1)}px";

    // set proportions of all range borders

    // top
    activeCellBorderContainer.children[0].style
        ..borderTopWidth = "2px"
        ..top = "-1px"
        ..left = "-1px"
        ..width = "${width+1}px";

    // right
    activeCellBorderContainer.children[1].style
        ..borderRightWidth = "2px"
        ..top = "-1px"
        ..left = "${width-2}px"
        ..height = "${height+1}px";

    // bottom
    activeCellBorderContainer.children[2].style
        ..borderBottomWidth = "2px"
        ..top = "${height-2}px"
        ..left = "-1px"
        ..width = "${width+1}px";

    // left
    activeCellBorderContainer.children[3].style
        ..borderLeftWidth = "2px"
        ..top = "-1px"
        ..left = "-1px"
        ..height = "${height+1}px";

    activeCellBorderContainer.hidden = !display;
  }
  
  void _updateActiveRowCssClass(int rowId) {
    //clean all old active rows
    var allActive = this.shadowRoot.querySelectorAll(".active-row");
    allActive.classes.remove("active-row");

    //activate the current rowId
    List<Cell> cellsInRow = cells[selectedRowId];
    for (Cell cell in cellsInRow) {
      if (cell.element != null) {
        cell.element.classes.add("active-row");
      }
    }
  }

  void _updateOverlays() {
    _overlayFixedRight.style
        ..left = "0px"
        ..top = "0px";

    _overlayFixedLeft.style
        ..left = "0px"
        ..top = "0px";

    _overlayScrollableLeft.style
        ..left = "0px"
        ..top = "-${_fixedPartHeight}px";

    _overlayScrollableRight.style
        ..left = "0px"
        ..top = "-${_fixedPartHeight}px";
  }

  void _updateScrollContainer() {
    _scrollContainer.style
        ..width = toPx(_overallWidth - _fixedPartWidth)
        ..height = toPx(_overallHeight - _fixedPartHeight)
        ..top = toPx(_fixedPartHeight)
        ..left = toPx(_fixedPartWidth);
  }

  void _updateScrollContainerContent() {
    var height = _scrollablePartHeight;
    var width = _scrollablePartWidth;

    // On Mac OS X scrollbar behaves differently - it is displayed as an overlay over the
    // content so we need to add scrollbar width to content height
    height += (_scrollbarOverlayed ? _scrollbarWidth : 0);
    width += (_scrollbarOverlayed ? _scrollbarWidth : 0);

    _scrollContainerContent.style
        ..width = toPx(_scrollablePartWidth)
        ..height = toPx(height);
  }

  void _updateHorizontalScrollbarExtension() {
    if (freezebarHorizontalVisible) {
      _verticalScrollbarExtension.style..top = toPx(_fixedPartHeight - 5);
      _verticalScrollbarExtension.classes.removeWhere((c) => c == "row-freezebar-extension-collapsed");
    } else {
      _verticalScrollbarExtension.style..top = toPx(_fixedPartHeight - 1);
      _verticalScrollbarExtension.classes.add("row-freezebar-extension-collapsed");
    }
  }

  void _updateVerticalScrollbarExtension() {
    if (freezebarVerticalVisible) {
      _horizontalScrollbarExtension.style..left = toPx(_fixedPartWidth - 5);
      _horizontalScrollbarExtension.classes.removeWhere((c) => c == "column-freezebar-extension-collapsed");
    } else {
      _horizontalScrollbarExtension.style..left = toPx(_fixedPartWidth - 1);
      _horizontalScrollbarExtension.classes.add("column-freezebar-extension-collapsed");
    }
  }

  void _updateFreezebarHorizontal() {
    // freezebar
    _freezebarHorizontalHandle.style
        ..width = toPx(_contentWidth)
        ..top = toPx(_fixedPartHeight - 4);

    _freezebarHorizontalHandleBar.style..width = toPx(_contentWidth - 46);

    _freezebarHorizontalDrop.style
        ..width = toPx(_contentWidth)
        ..top = toPx(_fixedPartHeight - 4);

    _freezebarHorizontalDropBar.style..width = toPx(_contentWidth - 46);

    if (freezebarHorizontalVisible || freezebarVerticalVisible) {
      _freezebarHorizontalHandle.classes.add("freezebar-horizontal-handle");
      _freezebarHorizontalHandle.classes.removeWhere((c) => c == "freezebar-horizontal-handle-invisible");
    } else {
      _freezebarHorizontalHandle.classes.add("freezebar-horizontal-handle-invisible");
      _freezebarHorizontalHandle.classes.removeWhere((c) => c == "freezebar-horizontal-handle");
    }

    // row headers
    _tbodyFixedLeft.children.last.style.height = toPx(freezebarHorizontalVisible ? 4 : 0);
    _tbodyFixedRight.children.last.style.height = toPx(freezebarHorizontalVisible ? 4 : 0);

    // freezebar cells
    var freezebarCells = _gridInnerContainer.querySelectorAll(".freezebar-horizontal-cell");

    if (!freezebarHorizontalVisible) {
      freezebarCells.classes.add("freezebar-hidden");
    } else {
      freezebarCells.classes.removeWhere((c) => c == "freezebar-hidden");
    }
  }

  void _updateFreezebarVertical() {
    // freezebar
    _freezebarVerticalHandle.style
        ..height = toPx(_contentHeight)
        ..left = toPx(_fixedPartWidth - 4);

    _freezebarVerticalHandleBar.style..height = toPx(_contentHeight - 24);

    _freezebarVerticalDrop.style
        ..height = toPx(_contentHeight)
        ..left = toPx(_fixedPartWidth - 4);

    _freezebarVerticalDropBar.style..height = toPx(_contentHeight - 24);

    if (freezebarHorizontalVisible || freezebarVerticalVisible) {
      _freezebarVerticalHandle.classes.add("freezebar-vertical-handle");
      _freezebarVerticalHandle.classes.removeWhere((c) => c == "freezebar-vertical-handle-invisible");
      _freezebarVertical.classes.removeWhere((c) => c == "freezebar-origin");
    } else {
      _freezebarVerticalHandle.classes.add("freezebar-vertical-handle-invisible");
      _freezebarVerticalHandle.classes.removeWhere((c) => c == "freezebar-vertical-handle");
      _freezebarVertical.classes.add("freezebar-origin");
    }

    // col headers
    _colgroupFixedLeft.children.last.style..width = toPx(freezebarVerticalVisible ? 4 : 0);
    _colgroupScrollableLeft.children.last.style..width = toPx(freezebarVerticalVisible ? 4 : 0);

    // freezebar cells
    var freezebarCells = _gridInnerContainer.querySelectorAll(".freezebar-vertical-cell");

    if (!freezebarVerticalVisible) {
      freezebarCells.classes.add("freezebar-hidden");
    } else {
      freezebarCells.classes.removeWhere((c) => c == "freezebar-hidden");
    }
  }

  void _updateRowHeadersBackground() {
    _rowHeadersBackground.style..height = toPx(_contentHeight);
  }

  void _updateColumnHeadersBackground() {
    _columnHeadersBackground.style..width = toPx(_contentWidth);
  }

  void _updateScrollbarShims() {
    _horizontalScrollbarShim.style..height = toPx(_scrollbarWidth);
    _verticalScrollbarShim.style..width = toPx(_scrollbarWidth);
  }

  void _updateGridOuterContainer() {
    _gridOuterContainer.style.width = toPx(_overallWidth);
    _gridOuterContainer.style.height = toPx(_overallHeight);
  }

  void _updateGridInnerContainer() {
    _gridInnerContainer.style
        ..width = toPx(_contentWidth)
        ..height = toPx(_contentHeight);
  }

  void _updateFixedOuterContainer() {
    _fixedOuterContainer.style
        ..width = toPx(_contentWidth)
        ..height = toPx(_fixedPartHeight);
  }

  void _updateQuadrantFixedLeft() {
    _quadrantFixedLeft.style
        ..width = toPx(_fixedPartWidth)
        ..height = toPx(_fixedPartHeight);
  }

  void _updateQuadrantFixedRight() {
    _quadrantFixedRight.style
        ..width = toPx(_contentWidth - _fixedPartWidth)
        ..height = toPx(_fixedPartHeight);
  }

  void _updateScrollableOuterContainer() {
    _scrollableOuterContainer.style
        ..width = toPx(_contentWidth)
        ..height = toPx(_contentHeight - _fixedPartHeight);
  }

  void _updateQuadrantScrollableLeft() {
    _quadrantScrollableLeft.style
        ..width = toPx(_fixedPartWidth)
        ..height = toPx(_contentHeight - _fixedPartHeight);
  }

  void _updateQuadrantScrollableRight() {
    _quadrantScrollableRight.style
        ..width = toPx(_contentWidth - _fixedPartWidth)
        ..height = toPx(_contentHeight - _fixedPartHeight);
  }
}

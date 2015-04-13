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
part of spreadsheet.editors;

/**
 * Custom cell editor for textual types.
 * Default name is #text
 */
@CustomTag('crius-text-cell-editor')
class TextCellEditor extends PolymerElement with CellEditor {

  static final Logger _logger = new Logger('CellEditor');

  DivElement get cellInput => $['cell-input'] as DivElement;
  Range range;

  factory TextCellEditor() => new Element.tag("crius-text-cell-editor");
  TextCellEditor.created() : super.created();

  @override
  void attached() {
    super.attached();
  }

  void keyPressAction(KeyboardEvent event) {
    if(event.keyCode == KeyCode.ENTER && !event.shiftKey && !event.ctrlKey) {
      event.preventDefault();
    }
  }

  void keyDownAction(KeyboardEvent event, Object detail, EventTarget sender) {
    if(event.keyCode == KeyCode.ENTER) {
      event.preventDefault();
    }

    if(event.keyCode == 10 || (event.keyCode == KeyCode.ENTER && event.ctrlKey)) {
      // TODO: Put new line on the cursor position when https://code.google.com/p/chromium/issues/detail?id=380690 gets fixed
      event.preventDefault();
    }
  }

  Node _getLastNestedNode(Node node) {
    while(node.hasChildNodes()) {
      node = node.lastChild;
    }

    return node;
  }

  int _getCharOffset(Node node) {
    if(node is Text) {
      return node.length;
    }

    return 0;
  }

  void focusAction(Event event) {
    var range = document.createRange();
    var sel = window.getSelection();
    var lastNode = _getLastNestedNode(cellInput);
    var charOffset = _getCharOffset(lastNode);

    range.setStart(lastNode, charOffset);
    range.collapse(true);
    sel.removeAllRanges();
    sel.addRange(range);
  }

  void blurAction(Event event) {
    // Note: It's very important that isActive flag has correct value, meaning that
    //       you have to set isActive to false before manually calling blur() over the text editor
    //       in deactivate() method.
    if(!isActive) {
      return;
    }

    asyncFire('edit-complete', detail: pullValue());
  }

  @override
  void pushValue(Object value) {
    super.pushValue(value);
    cellInput.innerHtml = (value == null)?"":value.toString();
  }

  @override
  Object pullValue() {
    return cellInput.innerHtml;
  }

  @override
  void activate() {
    super.activate();
    this.hidden = false;
    Future future = new Future(() {
      cellInput.focus();
    });
  }

  @override
  void deactivate() {
    super.deactivate();
    cellInput.blur();
    // Don't forget to remove selection due to Chromium's bug !!!
    window.getSelection().removeAllRanges();
    Future future = new Future(() {
      this.hidden = true;
    });
  }
}
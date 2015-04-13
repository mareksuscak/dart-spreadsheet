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
library spreadsheet.model;

import 'dart:html';
import 'package:collection/wrappers.dart';
import 'package:logging/logging.dart';
import 'package:spreadsheet/renderers/renderers.dart';
import 'package:spreadsheet/spreadsheet.dart';

part 'row.dart';
part 'column.dart';
part 'column_collection.dart';
part 'row_collection.dart';
part 'cell.dart';
part 'cell_collection.dart';
part 'cell_location.dart';
part 'cell_range.dart';
part 'quadrant.dart';
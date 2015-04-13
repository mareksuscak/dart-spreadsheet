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

class Quadrant {
  bool top;
  bool left;
  bool get right => !left;
  bool get bottom => !top;
  bool get q0 => left && top;
  bool get q1 => right && top;
  bool get q2 => left && bottom;
  bool get q3 => right && bottom;
  
  Quadrant(this.left, this.top);
}
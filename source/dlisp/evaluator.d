/*
 evaluator.d
 dLISP
 
 Author: Fredrik Olsson <peylow@treyst.se>
 Copyright (c) 2005 Treyst AB, <http://www.treyst.se>
 All rights reserved.
 
 This file is part of dLISP.
 dLISP is free software; you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation; either version 2.1 of the License, or
 (at your option) any later version.
 
 dLISP is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with dLISP; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

module dlisp.evaluator;

private {
}

public template Evaluator() {
  
  public {
  import std.range;
  import std.stdio;
  import std.string;
  import std.exception;
    
    bool[string] tracefuncs;
    uint evalcount = 0;
    uint tracetabs = 2;
    uint allowLists = 0;
    
    uint tracelevel = 0;
    
    void addTrace(string name) {
      if (!(name in tracefuncs)) {
        tracefuncs[name] = true;
      }
    }
    
    void removeTrace(string name) {
      if (name in tracefuncs) {
        tracefuncs.remove(name);
      } 
    }
    
    Cell* eval(Cell* cell, bool leavebound = false) {
      evalcount++;
      if (isAtom(cell)) {
        return cell;
      }
      if (isBoundValue(cell)) {
        switch (cell.cellType) {
          case CellType.ctBINT:
            return newInt(*cell.pintValue);
          case CellType.ctBFLOAT:
            return newFloat(*cell.pfloatValue);
          case CellType.ctBSTR:
            return newStr(*cell.pstrValue);        
	  default: enforce(false, "svn code bug!");
        }
      }
      if (cell.cellType == CellType.ctSYM) {
        if (environment.isBound(cell.name)) {
          Cell* temp = environment[cell.name];
          if (!leavebound && isBoundValue(temp)) {
            return eval(temp);
          } else {
            return temp;
          }
        } else {
          throw new UnboundSymbolState("Unbound symbol: " ~ cell.name, cell.pos); 
        }
      }
      Cell* func = eval(cell.car);
      string name = cell.car.name;
      switch (func.cellType) {
        case CellType.ctFUNC:
          // Lots of magic!!!
          bool ismacro = func.ismacro;
          Cell* args = func.cdr;
          Cell* params = cell.cdr;
          Cell*[] macroforms;
          environment.pushScope();
          try {
            bool dotrace = (name in tracefuncs) != null;
            Cell* parms = null;
            if (dotrace) {
              tracelevel +=tracetabs;
            }
            bool isoptional = false;
            string isrest = "";
            while (args) {
              if (args.car.name == "&OPTIONAL" ) {
                isoptional = true;
              } else if (args.car.name == "&REST") {
                args = args.cdr;
                isrest = args.car.name;
              } else {
                // string name;
                if (params) {
                  if (ismacro) {
                    cell = params.car;
                  } else {
                    cell = eval(params.car);
                  }
                  params = params.cdr;
                } else {
                  if (isoptional) {
                    if (isList(args.car)) {
                      cell = args.car.cdr.car;
                    } else {
                      cell = null;
                    }
                  } else {
                    throw new ArgumentState((ismacro ? "Macro " : "Function ") ~ 
                                                func.name ~ " got to few arguments.", func.pos);
                  }
                }
                if (dotrace) {
                  parms = appendToList(parms, newCons(cell, null));
                }
                if (isList(args.car)) {
                  environment.addLocal(args.car.car.name, cell);
                } else {
                  environment.addLocal(args.car.name, cell);
                }
              }
              args = args.cdr;
            }
            if (params) {
              if (isrest == "") {
                throw new ArgumentState((ismacro ? "Macro " : "Function ") ~ 
                                            func.name ~ " got to many arguments.", func.pos);
              } else {
                if (ismacro) {
                  environment.addLocal(isrest, params);
                } else {
                  Cell* rest = null;
                  while (params) {
                    rest = appendToList(rest, newCons(eval(params.car), null));
                    params = params.cdr;
                  }
                  environment.addLocal(isrest, rest);
                }
              }
            } else {
              if (isrest != "") {
                environment.addLocal(isrest, null);
              }
            }
            if (dotrace) {
              writefln(replicate(" ", tracelevel), "Trace ", name, " in: ", cellToString(parms));
            }
            func = func.car;
            while (func) {
              cell = eval(func.car);
              if (ismacro) {
                macroforms ~= cell;
              }
              func = func.cdr;
            }
          } finally {
            environment.popScope();
          }
          if (ismacro) {
            foreach (Cell* mcell; macroforms) {
              // writefln(cellToString(mcell));
              cell = eval(mcell);
            }
          }
          break;
        case CellType.ctPREDEF:
          cell = func.func(this, cell);
          break;
        default:
/*          if (allowLists == 0) {
            throw new EvalState("Unexpected list", func.pos);
          }
*/      }
      if (name in tracefuncs) {
        writefln(replicate(" ", tracelevel), "Trace ", name, " out: ", cellToString(cell));
        tracelevel -= tracetabs;
      }
      return cell;
    }
    
  }
  
}

/*
 environment.d
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

module dlisp.environment;

private {
  import std.math;
  import std.string;
  import undead.cstream;

  import dlisp.dlisp;
}

public class Environment {
  private Cell*[string] _globals;
  private Cell*[string][] _restore;
  private string[][] _remove;
  
  public {

    this() {
    }
    
    void bindPredef(string name, PredefFunc func, string docs = "", bool ismacro = false) {
      this[name] = newPredef(name, func, docs, ismacro);
    }
    
    void bindValue(string name, int* pointer) {
      this[name] = newBoundInt(pointer);
    }

    void bindValue(string name, real* pointer) {
      this[name] = newBoundFloat(pointer);
    }
    
    void bindValue(string name, string* pointer) {
      this[name] = newBoundStr(pointer);
    }
    
    void clonePredef(string name, string newname) {
      this[newname] = this[name.toUpper()];
    }
  
    string[] allFuncs() {
      string[] ret;
      foreach (string key, Cell* cell; _globals) {
        if (isFunc(cell)) {
          if (cell.docs != "") {
            ret ~= cell.name;
          }
        }
      }
      return ret;
    }
        
    bool isBound(string key) {
      return (key in _globals) != null;
    }
    
    void unbind(string key) {
      if (!isBound(key)) {
        throw new Exception("Unbound symbol: " ~ key);
      }
      _globals.remove(key);
    }
    
    void refresh() {
      this._globals.rehash;
    }
    
    void addLocal(string key, Cell* value) {  
      Cell** tcell = key in _globals;
      if (tcell) {
        _restore[_restore.length - 1][key] = *tcell;
      } else {
        _remove[_remove.length - 1] ~= key;
      }
      _globals[key] = value;
    }
    
    void pushScope() {
      _restore.length = _restore.length + 1;
      _remove.length = _remove.length + 1;
    }
    
    void popScope() {
      if (_restore.length == 0) {
        throw new Exception("Local stack is empty");
      }
      foreach(string key, Cell* cell; _restore[_restore.length - 1]) {
        _globals[key] = cell;
      }
      foreach(string key; _remove[_remove.length - 1]) {
        _globals.remove(key);
      }
      _restore.length = _restore.length - 1;
      _remove.length = _remove.length - 1;  
    }
    
    Cell* opIndex(string key) {
      if (!isBound(key)) {
        throw new Exception("Unbound symbol: " ~ key);
      }
      return _globals[key];
    }

    Cell* opIndexAssign(Cell* value, string key) {
      _globals[key.toUpper()] = value;
      return value;
    }

  }
    
}

public Environment addToEnvironment(Environment environment) {
  environment = new Environment();
  return environment;
}

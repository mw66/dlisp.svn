/*
 states.d
 dLISP
 
 Created by Fredrik Olsson on 2005-12-29.
 Copyright (c) 2005 __MyCompanyName__. All rights reserved.
 */

module dlisp.states;

private {
  import std.string;
  
  import dlisp.types;
}

public {
  
  class DLispState : Exception {
    Pos pos;
    public this(string msg) {
      super(msg);
    }
    public this(string msg, Pos pos) {
      this.pos = pos;
      this(msg);
    }
    public string stateName() {
      return "STATE";
    }
    public string[] stateNames() {
      static string[] tmp = ["STATE"];
      return tmp;
    }
  }

  class ErrorState : DLispState {
    this(string msg, Pos pos) {
      super(msg, pos);
    }
    public override string stateName() {
      return "ERROR-STATE";
    }
    public override string[] stateNames() {
      static string[] tmp = ["ERROR-STATE"];
      return super.stateNames() ~ tmp;
    }
  }
  
  class ParseState : ErrorState {
    this(string msg, Pos pos) {
      super(msg, pos);
    }
    public override string stateName() {
      return "PARSE-STATE";
    }
    public override string[] stateNames() {
      static string[] tmp = ["PARSE-STATE"];
      return super.stateNames() ~ tmp;
    }
  }
  
  class EvalState : ErrorState {
    this(string msg, Pos pos) {
      super(msg, pos);
    }
    public override string stateName() {
      return "EVAL-STATE";
    }
    public override string[] stateNames() {
      static string[] tmp = ["EVAL-STATE"];
      return super.stateNames() ~ tmp;
    }
  }
  
  public class UnboundSymbolState : EvalState {
    this(string msg, Pos pos) {
      super(msg, pos);
    }
    public override string stateName() {
      return "UNBOUND-STATE";
    }
    public override string[] stateNames() {
      static string[] tmp = ["UNBOUND-STATE"];
      return super.stateNames() ~ tmp;
    }
  } 
  
  class ArgumentState : EvalState {
    this(string msg, Pos pos) {
      super(msg, pos);
    }
    public override string stateName() {
      return "ARGUMENT-STATE";
    }
    public override string[] stateNames() {
      static string[] tmp = ["ARGUMENT-STATE"];
      return super.stateNames() ~ tmp;
    }
  }
  
  class TypeState : EvalState {
    this(string msg, Pos pos) {
      super(msg, pos);
    }
    public override string stateName() {
      return "TYPE-STATE";
    }
    public override string[] stateNames() {
      static string[] tmp = ["TYPE-STATE"];
      return super.stateNames() ~ tmp;
    }
  }
  
  class FileState : ErrorState {
    this(string msg) {
      super(msg, pos);
    }
    public override string stateName() {
      return "FILE-STATE";
    }
    public override string[] stateNames() {
      static string[] tmp = ["FILE-STATE"];
      return super.stateNames() ~ tmp;
    }
  }
    
}

/*
 parse.d
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

module dlisp.parser;


public template Parser() {
  
  private {
    import undead.stream;
    import std.stdio;
    import std.string;
    import std.conv;
    import std.regex;
    import std.uni;

    import dlisp.dlisp;
    import dlisp.types;
  }
  
  public {
    
    Cell* parse(string source) {
      return parse(new MemoryStream(cast(char[])source));
    }
    
    // Workaround for bug?
    Cell* parse(Stream _stream) {
      char ch = ' ';
      static Stream stream;
      static Pos pos;
      static uint backquotes = 0;
      
      void nextch() {
        char tch;
        if (ch == char.init)
          throw new ParseState("Unexpected end of parse stream", pos);
        ch = tch = stream.getc();
        if (ch == '\n') {
          pos.row++;
          pos.col = 0;
        } else {
          pos.col++;
        }
      }
      
      char lookahead() {
        char tch = stream.getc();
        stream.ungetc(tch);
        return tch;
      }
      
      void skipWhite(bool noconsume = false) {
        if (noconsume && !std.uni.isWhite(ch) && ch != ';')
          return;
        do {
          nextch();
          if (ch == ';') {
            do {
              nextch();
            } while (ch != '\n' && ch != '\r');
          }
        } while(std.uni.isWhite(ch));
      }
      
      Cell* parseAtom(bool havech) {
        Pos _pos = pos;
        char[] tmp = [];
        if (!havech)
          skipWhite();
        if (ch == '"') {
          while(1) {
            nextch();
            if (ch == '"') {
              if (lookahead() == '"')
                nextch();
              else
                break;
            }
            tmp ~= ch;
          }
          nextch();
          return newStr(cast(string)tmp, _pos);
        } else { 
          while (matchFirst([ch], regex("[a-zA-Z0-9-]")) || matchFirst([ch], regex("[_.!@$&+*%/><='~^]"))) {
            tmp ~= ch;
            nextch();
          }
          if (tmp == "") {
            throw new ParseState("Unexpected character in parse stream", pos);
          }
          try {
            if (indexOf(tmp, ".") == -1) {
              return newInt(to!int(tmp), _pos);
            } else {
              return newFloat(to!real(tmp), _pos);
            }
          } catch (std.conv.ConvException e) {
            return newSym(cast(string)tmp, _pos);
          }
        }
      }
      
      Cell* parseToken(bool havech = false) {
        
        Cell* parseList(bool havech = false) {
          if (!havech)
            skipWhite();
          if (ch == ')') {
            if (lookahead() != char.init)
              nextch();
            return null;
          } else {
            Cell* car = parseToken(true);
            Cell* cdr = null;
            skipWhite(true);
            
            if (ch == '.') {
              cdr = parseToken();
              skipWhite(true);
              if (ch != ')') {
                throw new ParseState("End of list expected", pos);
              } else {
                if (lookahead() != char.init)
                  nextch();          
              }
            } else {
              cdr = parseList(true);
            }
            return newCons(car, cdr);
          }
        }
        
        if (!havech)
          skipWhite();
        switch(ch) {
          case ')': 
            throw new ParseState("Unexpected parateses", pos);
            break;
          case '(':
            return parseList();
            break;
          case '\'':
            return newCons(newSym("QUOTE"), newCons(parseToken(), null));
            break;
          case '`':
            backquotes++;
            try {
              return newCons(newSym("BACK-QUOTE"), newCons(parseToken(), null));
            }
            finally {
              backquotes--;
            }
            break;
          case ',':
            if (backquotes == 0) {
              throw new ParseState("Comma not inside backquote", pos);
            }
            return newCons(newSym("COMMA-QUOTE"), newCons(parseToken(), null));
            break;
          default:
            return parseAtom(true);
            break;
        }
      }
      
      if (stream !is _stream) {
        pos.row = 1; pos.col = 0;
      }
      stream = _stream;
      ch = ' ';
      Cell* ret = parseToken();
      skipWhite(true);
      if (ch != char.init) {
        _stream.ungetc(ch);
      }
      return ret;
    }
    
    Cell* parseEvalPrint(string source, bool silent = false) {
      return parseEvalPrint(new MemoryStream(cast(char[])source), silent);
    }
    
    Cell* parseEvalPrint(Stream stream, bool silent = false) {
      Cell* cell = null;
      while (!stream.eof) {
        cell = this.parse(stream);
        // writefln(cellToString(cell));
        cell = this.eval(cell);
        if (!silent) {
          writefln(cellToString(cell));
        }
      }
      return cell;
    }
    
  }
  
}

//+------------------------------------------------------------------+
//|                                                   ClassLabel.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
class Label 
   { 
   private: 
      string            Name;   
      int               X;               // X-axis distance 
      int               Y;               // Y-axis distance 
      string            Font;            // Font 
      int               FontSize;        // Font size 
      color             Color;           // Color 
      ENUM_ANCHOR_POINT Anchor;          // Anchor type 
      ENUM_BASE_CORNER  Corner;
      bool              Back;            // Background object 
      bool              Selection;       // Highlight to move 
      bool              Hidden;          // Hidden in the object list 
      long              ZOrder;          // Priority for mouse click
   
   public: 
      //--- Constructor 
      Label(void){};
      Label(string name, int position)
      {
         Name = name;   
         X = InpY;              
         Y = InpY + (InpFontSize+2) * position;               
         Font = InpFont;            
         FontSize = InpFontSize;        
         Color = InpColor;           
         Anchor = InpAnchor;          
         Corner = InpCorner;
         Back = InpBack;           
         Selection = InpSelection;       
         Hidden = InpHidden;         
         ZOrder = InpZOrder;    
      };   
      
      void Draw()
      {
         //--- Create and set info label
         ObjectCreate(NULL,Name,OBJ_LABEL,0,0,0);
         ObjectSetInteger(NULL,Name,OBJPROP_XDISTANCE,X); 
         ObjectSetInteger(NULL,Name,OBJPROP_YDISTANCE,Y);
         ObjectSetInteger(NULL,Name,OBJPROP_CORNER,Corner);     
         //--- set text font 
         ObjectSetString(NULL,Name,OBJPROP_FONT,Font); 
         //--- set font size 
         ObjectSetInteger(NULL,Name,OBJPROP_FONTSIZE,FontSize); 
         //--- set anchor type 
         ObjectSetInteger(NULL,Name,OBJPROP_ANCHOR,Anchor); 
         //--- set color 
         ObjectSetInteger(NULL,Name,OBJPROP_COLOR,Color); 
         //--- display in the foreground (false) or background (true) 
         ObjectSetInteger(NULL,Name,OBJPROP_BACK,Back); 
         //--- enable (true) or disable (false) the mode of moving the label by mouse 
         ObjectSetInteger(NULL,Name,OBJPROP_SELECTABLE,Selection); 
         ObjectSetInteger(NULL,Name,OBJPROP_SELECTED,Selection); 
         //--- hide (true) or display (false) graphical object name in the object list 
         ObjectSetInteger(NULL,Name,OBJPROP_HIDDEN,Hidden); 
         //--- set the priority for receiving the event of a mouse click in the chart 
         ObjectSetInteger(NULL,Name,OBJPROP_ZORDER,ZOrder);          
      };      
      
      void Update(string text, color textColor)
      {
         ObjectSetInteger(NULL,Name,OBJPROP_COLOR,textColor); 
         ObjectSetString(NULL,Name,OBJPROP_TEXT, text);     
      };
      
      void SetXY(int x, int y)
      {
         ObjectSetInteger(NULL,Name,OBJPROP_XDISTANCE,x); 
         ObjectSetInteger(NULL,Name,OBJPROP_YDISTANCE,y);          
      }       
      
      void SetPoint(int anchor, int corner)
      {
         ObjectSetInteger(NULL,Name,OBJPROP_ANCHOR,anchor); 
         ObjectSetInteger(NULL,Name,OBJPROP_CORNER,corner);             
      }        
      
      void Size(int size)
      {
         FontSize = size;     
      };      
      
      ~Label(void){ObjectDelete(NULL, Name);};                         
  };  

/*  
class GraphicalObject
   {
   
   
   }
*/

class Button
   {
      private:      
      string            name;            // button name 
      int               sub_window;             // subwindow index 
      int               x;                    // X coordinate 
      int               y;                      // Y coordinate 
      int               width;                 // button width 
      int               height;                // button height 
      ENUM_BASE_CORNER  corner; // chart corner for anchoring 
      string            text;            // text 
      string            font;             // font 
      int               font_size;             // font size 
      color             clr;             // text color 
      color             back_clr;  // background color 
      color             border_clr;       // border color 
      bool              state;              // pressed/released 
      bool              back;               // in the background 
      bool              selection;          // highlight to move 
      bool              hidden;              // hidden in the object list 
      long              z_order;        

      public:      
      Button(void){};
      Button(string btnName)
      {
         name=btnName;             // button name 
         sub_window=0;             // subwindow index 
         x=0;                      // X coordinate 
         y=0;                      // Y coordinate 
         width=50;                 // button width 
         height=18;                // button height 
         corner=CORNER_LEFT_UPPER; // chart corner for anchoring 
         text="Button";            // text 
         font="Arial";             // font 
         font_size=10;             // font size 
         clr=clrBlack;             // text color 
         back_clr=C'236,233,216';  // background color 
         border_clr=clrNONE;       // border color 
         state=false;              // pressed/released 
         back=false;               // in the background 
         selection=false;          // highlight to move 
         hidden=false;              // hidden in the object list 
         z_order=0;           
      };  
 
      void Draw()
      {
         if(!ObjectCreate(NULL,name,OBJ_BUTTON,sub_window,0,0)) 
           { 
            Print(__FUNCTION__, 
                  ": failed to create the button! Error code = ",GetLastError()); 
            return;
           }       
         //--- set button coordinates 
            ObjectSetInteger(NULL,name,OBJPROP_XDISTANCE,x); 
            ObjectSetInteger(NULL,name,OBJPROP_YDISTANCE,y); 
         //--- set button size 
            ObjectSetInteger(NULL,name,OBJPROP_XSIZE,width); 
            ObjectSetInteger(NULL,name,OBJPROP_YSIZE,height); 
         //--- set the chart's corner, relative to which point coordinates are defined 
            ObjectSetInteger(NULL,name,OBJPROP_CORNER,corner); 
         //--- set the text 
            ObjectSetString(NULL,name,OBJPROP_TEXT,text); 
         //--- set text font 
            ObjectSetString(NULL,name,OBJPROP_FONT,font); 
         //--- set font size 
            ObjectSetInteger(NULL,name,OBJPROP_FONTSIZE,font_size); 
         //--- set text color 
            ObjectSetInteger(NULL,name,OBJPROP_COLOR,clr); 
         //--- set background color 
            ObjectSetInteger(NULL,name,OBJPROP_BGCOLOR,back_clr); 
         //--- set border color 
            ObjectSetInteger(NULL,name,OBJPROP_BORDER_COLOR,border_clr); 
         //--- display in the foreground (false) or background (true) 
            ObjectSetInteger(NULL,name,OBJPROP_BACK,back); 
         //--- set button state 
            ObjectSetInteger(NULL,name,OBJPROP_STATE,state); 
         //--- enable (true) or disable (false) the mode of moving the button by mouse 
            ObjectSetInteger(NULL,name,OBJPROP_SELECTABLE,selection); 
            ObjectSetInteger(NULL,name,OBJPROP_SELECTED,selection); 
         //--- hide (true) or display (false) graphical object name in the object list 
            ObjectSetInteger(NULL,name,OBJPROP_HIDDEN,hidden); 
         //--- set the priority for receiving the event of a mouse click in the chart 
            ObjectSetInteger(NULL,name,OBJPROP_ZORDER,z_order);  
      }  
      
      void SetXY(int x, int y)
      {
         ObjectSetInteger(NULL,name,OBJPROP_XDISTANCE,x); 
         ObjectSetInteger(NULL,name,OBJPROP_YDISTANCE,y);          
      } 
      
      void SetSize(int x, int y)
      {
         ObjectSetInteger(NULL,name,OBJPROP_XSIZE,x); 
         ObjectSetInteger(NULL,name,OBJPROP_YSIZE,y);          
      }       
      
      void SetText(string text)
      {
         ObjectSetString(NULL, name, OBJPROP_TEXT, text);
      }
      
      bool GetState()
      {
         return ObjectGetInteger(NULL,name,OBJPROP_STATE);
      }
      
      void Hide()
      {
         if(ObjectFind(name>=0))
            if(!ObjectDelete(NULL, name))
               Print("Cannot hide ", name, " object. Error = ", GetLastError());
      }
      
      ~Button(void){ObjectDelete(NULL, name);};              
   };   
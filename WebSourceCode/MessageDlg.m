%================================================================================
% THIS DIALOG BOX ALLOWS NUMERIC VALUES TO BE ENTERED, LAYOUT
%
%                     +--------------------------------+
%                     |       ... PromptString1 ...    |
%                     |       ... PromptString2 ...    |
%                     |                                |
%                     |              [CLOSE]           |
%                     +--------------------------------+
%
% Note:    The width of the dialog is adjusted to fit the longer of string1 or 2
% BUTTONS: CLOSE
%================================================================================
function MessageDlg(PromptString1, PromptString2)
%begin
   global dlg
   
   %DIALOG SETUP
   LightBlue = [0.85 0.85 1];
   DarkBlue  = [0.70 0.70 0.9];
   W         = 300; 
   H         = 110;  
   
   %DIALOG WINDOW
   dlg    = dialog('Units', 'pixels', 'Position',  [20 20 W H],  'Color', LightBlue); 
   Title1 = Createuicontrol('edit',  PromptString1, LightBlue, [1 75 W 36]);
   Title2 = Createuicontrol('edit',  PromptString2, LightBlue, [1 40 W 36]);
   
   %ADJUST THE WIDTH TO FIT THE LENGTH OF THE LONGER STRING
   P1 = get(Title1, 'Extent');
   W1 = P1(3)+20;
   P2 = get(Title2, 'Extent');
   W2 = P2(3)+20;
   W  = max([W1, W2, 220]);
   set(dlg,    'Position', [20  20    W   H]);
   set(Title1, 'Position', [ 1  75    W  36]);
   set(Title2, 'Position', [ 1  40    W  36]);

   %OK AND CANCEL BUTTONS CENTERED:
   Close = Createuicontrol('pushbutton', 'Close', DarkBlue, [W/2-50 5 100 30]); 
   set(Close, 'Callback',  @OnClickClose);
   MoveToCenter(dlg);
   uiwait(dlg);
%end






%==========================================================
% CREATES A UI CONTROL MOST ARE SAME:
%==========================================================
function uictrl = Createuicontrol(style, title, bkcolor, position)
%begin
   global dlg
   
   uictrl = uicontrol( 'Style',               style,                 ...
                       'Units',               'pixels',              ...
                       'Position',            position,              ...
                       'HorizontalAlignment', 'center',              ...
                       'fontweight',          'normal',              ...
                       'fontname',            'Arial Unicode MS',    ...
                       'fontsize',            14,                    ...
                       'BackgroundColor',     bkcolor,               ...
                       'String',              title,                 ...
                       'Parent',              dlg);     
%end



%==========================================================
% OK BUTTON PRESSED
%==========================================================
function OnClickClose(src, evt)
%begin
    %close current figure
    delete(get(0,'CurrentFigure'));
%end






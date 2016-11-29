%==========================================================
% MOVE THE DIALOG BOX TO THE CENTER OF THE SCREEN:
%==========================================================
function MoveToCenter(dlg)
%begin
   %get the size of the screen in pixels:
   scrsz   = get(0,'ScreenSize');   
   Wscreen = scrsz(3);
   Hscreen = scrsz(4);
   
   %get the size of the dialog box in pixels:   
   set(dlg, 'Units', 'pixels');
   P = get(dlg, 'Position');
   
   %calculate the new coordinates in the center:
   Wdlg = P(3);
   Hdlg = P(4);
   x0   = (Wscreen-Wdlg)/2;
   y0   = (Hscreen-Hdlg)/2;
   set(dlg, 'Position', [x0 y0 Wdlg Hdlg]);
%end
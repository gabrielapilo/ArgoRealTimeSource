function save_fig(arg1,arg2)
%save_fig:  Save an image of the current Figure window in a file.
%
%     Usage: save_fig (filename, 'clobber'|'noclobber')
%
%     Filename can contain directory, and the extension must be
%     '.gif' or an imwrite.m option ('jpg','tif', etc). 
%     (No extension defaults to '.gif')
%     using '.ps' calls standard Matlab print(-depsc filename)
%                 then /home/scripts/packmat
%
%        Notes:
%
%     The gif file is actually created by creating a tif file which is then
%     piped through tifftopnm and ppmtogif. The time to run save_fig can be
%     halved by just creating a tif file and running the conversion offline.
%
%     Waring/Griffin/McIntosh Sept 1998  

% $Id: save_fig.m,v 1.4 2000/11/03 02:56:48 mansbrid Exp $
% Copyright J. V. Mansbridge, CSIRO, Thursday October  7 18:44:10 EST 1999

if nargin<1,error('Must specify filename');end

if nargin<2
 clobber=1;
else
 clobber=strcmp(arg2,'clobber');
end


%...Decode filename and directory...

nsl=max(findstr(arg1,filesep));
ndot=max(findstr(arg1,'.'));
if isempty(nsl),
  nfirst=1;
  dir=[];
else
  nfirst=nsl+1;
  dir=arg1(1:nsl);
end
if isempty(ndot),
  nlast=length(arg1);
  ext=['.gif'];
else
  nlast=ndot-1;
  ext=arg1(ndot:length(arg1));
end

file=arg1(nfirst:nlast);

filenam = [dir,file,ext];

%...Check if file exists...

if (~clobber)
  file_status=exist(filenam);
  if file_status==2,
    reply=input('File exists: overwrite ? > ','s');
    if ~strcmp(lower(reply),'y'),return;end
  end
end

if strcmp(ext,'.ps')
  filetmp = [dir file 'tmp.ps'];
  print('-depsc', filetmp)
  unixcommand=['packmat < ',filetmp,' >! ',filenam];
  eval(['unix(''',unixcommand,''');'])
  unixcommand=['\rm -f ',filetmp];
  eval(['unix(''',unixcommand,''');'])
else

  %...Now convert to image, 
  [im,map]=frame2im(getframe(gcf));
  [imind,cm] = rgb2ind(im,256);  
  
  %  Save in requested form

  if strcmp(ext,'.gif')
      imwrite(imind,cm,filenam,'gif');
%     filetif = [dir,file,'.tif'];
%     if isempty(map) % check for a truecolor display
%       imwrite(im,filetif);
%     else
%       imwrite(im,map,filetif);
%     end

%     unixcommand=['tifftopnm ',filetif,' | ppmquant 256 | ppmtogif >! ',filenam];
%     eval(['unix(''',unixcommand,''');'])
% 
%     unixcommand=['\rm -f ',filetif];
%     eval(['unix(''',unixcommand,''');'])
  else
    if isempty(map) % check for a truecolor display
      imwrite(im,filenam);
    else
      imwrite(im,map,filenam);
    end
  end
end



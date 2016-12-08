% GET_MAP    Interactively puts a coastline map in the current figure.
% Simply type 'get_map' and answer the questions.  Note that longitude
% may be between -180 and +360 degrees and latitude may be between -90
% and +90 degrees.

%     Copyright J. V. Mansbridge, CSIRO, Wed Jan 18 16:10:34 EST 1995

xmin = input('minimum longitude:  ');
xmax = input('maximum longitude:  ');
ymin = input('minimum latitude:  ');
ymax = input('maximum latitude:  ');
hold off
axis([xmin xmax ymin ymax])
hold on
gebco
sa = menu('Save as an encapsulated postscript file?', 'yes', 'no');
if sa == 1
  name = input('file name:  ', 's');
  str = [ 'print -deps ' name ];
  eval(str)
end
hold off


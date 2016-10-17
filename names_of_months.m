function [names, num_days, middle_of_month] = names_of_months(month_no)
% Returns variables related to the months of the year.
%
%   INPUT
%
% month_no: if this is an integer between 1 and 12 then the information
%           returned will be for that month only. If no argument is passed
%           then the returned information will be for all 12 months.
%
%   OUTPUT:
% names: the names of the months as strings within cells if there is no
%        input argument or as a single string for the requested month if
%        there is an input argument
% num_days: the number of days in each month as a vector (february == 28.25)
% middle_of_month: the number of days into the year when the middle of the
%                  month occurs. 

% $Id: names_of_months.m,v 1.1 1997/11/06 03:21:22 mansbrid Exp $
% Copyright J. V. Mansbridge, CSIRO, Tue Jul 22 17:42:51 EST 1997

x = cell(12, 1);
x{1} = 'january';
x{2} = 'february';
x{3} = 'march';
x{4} = 'april';
x{5} = 'may';
x{6} = 'june';
x{7} = 'july';
x{8} = 'august';
x{9} = 'september';
x{10} = 'october';
x{11} = 'november';
x{12} = 'december';

y = [31 28.25 31 30 31 30 31 31 30 31 30 31];

z = y/2 + [0 cumsum(y(1:11))];

if nargin == 0
  if nargout <= 1
    names = x;
  elseif nargout == 2
    names = x;
    num_days = y;
  elseif nargout == 3
    names = x;
    num_days = y;
    middle_of_month = z;
  end
else
  if round(month_no) ~= month_no
    error('the input argument must be an integer')
  elseif (month_no < 1) | (month_no > 12)
    error('the input argument must be an integer between 1 and 12')
  end    
  if nargout <= 1
    names = x{month_no};
  elseif nargout == 2
    names = x{month_no};
    num_days = y(month_no);
  elseif nargout == 3
    names = x{month_no};
    num_days = y(month_no);
    middle_of_month = z(month_no);
  end
end  

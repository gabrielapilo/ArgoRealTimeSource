function continents(color,edge,nmin)

%CONTINENTS(COLOR,EDGE,NMIN) Draw continents as patches with color COLOR
%                            edge color EDGE and NMIN points in coastline

global ARGO_SYS_PARAM
if nargin<1,color=[.6 .6 .6];end
if nargin<2,edge='k';end
if nargin<3,nmin=3;end

load (ARGO_SYS_PARAM.continents);

bad=find(isnan(x_map));

lastlen=0;
x=[];
y=[];
for i=1:length(bad)-1
  i1=bad(i)+1;
  i2=bad(i+1)-1;
  len=i2-i1+1;
  if len>=nmin,
    if (len~=lastlen&i>1) | i==length(bad)-1,
      patch(x,y,color,'edgecolor',edge);
      x=x_map(i1:i2)';
      y=y_map(i1:i2)';
    else
      x=[x x_map(i1:i2)'];
      y=[y y_map(i1:i2)'];
    end
    lastlen=len;
  end
end

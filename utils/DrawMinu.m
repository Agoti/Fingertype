function obj = DrawMinu(varargin)
% Draw minutiae
%
% Usages:
%   DrawMinu(minu)
%   DrawMinu(fig,minu)
%   DrawMinu(fig,minu,minuColor)
%   DrawMinu(fig,minu,minuColor,textColor)
%
% Inputs:
%   fig         - 1,2,3....
%   minu        - [x y dir], dir is defined in a different coordinate (y axis points up, x axis points right)
%   minuColor   - 'r','b','g',...
%   textColor   - 'r','b','g',...

% Jianjiang Feng
% 2004-01


[fig,minu,minuColor,textColor] = ParseInputs(varargin{:});

obj = [];
if isempty(minu)
    return
end

r = 5;
lwidth = 2;
tail = 3*r;

if length(minuColor)==2
    minuColors = [minuColor];
elseif length(minuColor)==1
    minuColors = [minuColor 'r'];
end

obj = zeros(size(minu,1),2);
figure(fig),hold on
for i = 1:size(minu,1)
    mcolor = minuColors(1);
    if size(minu,2)>=5
        if minu(i,5)==0
            mcolor = minuColors(2);
        end
    end
    x = minu(i,1);
    y = minu(i,2);
    obj(i,1) = rectangle('Position',[x-r,y-r,2*r+1,2*r+1],'Curvature',[0,0],'EdgeColor',mcolor,'LineWidth',lwidth);
    if size(minu,2)==3
    obj(i,2) = line([x x+tail*cos(minu(i,3)*pi/180)],[y y-tail*sin(minu(i,3)*pi/180)],'Color',mcolor,'LineWidth',lwidth);
    end
    strMinuNo = num2str(i);
    if ~isempty(textColor)
        obj(i,3) = text(x+5,y+5,strMinuNo,'Color',textColor,'fontsize',18);
    end
end


%---------------------------
function [fig,minu,minuColor,textColor] = ParseInputs(varargin)

fig = 1;
minuColor = 'r';
textColor = [];

switch length(varargin)
case 1
    minu = varargin{1};
case 2
    fig = varargin{1};
    minu = varargin{2};
case 3
    fig = varargin{1};
    minu = varargin{2};
    minuColor = varargin{3};
case 4
    fig = varargin{1};
    minu = varargin{2};
    minuColor = varargin{3};
    textColor = varargin{4};
otherwise
    error('Too many input arguments.  See HELP DrawMinu');
end
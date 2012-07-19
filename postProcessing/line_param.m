function [m,b]=line_param(x0,x1,y0,y1)
%Calculates the parameters of a line (m,b)

%m=(y0-b)/x0;
%b=y1-(m*x1);

b=(y1-((x1*y0)/x0))/(1-(x1/x0));
m=(y0-b)/x0;

end




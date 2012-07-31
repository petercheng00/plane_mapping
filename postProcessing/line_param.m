function [m,b]=line_param(x0,x1,y0,y1)
%Calculates the parameters of a line (m,b)

%m=(y0-b)/x0;
%b=y1-(m*x1);

%b=(y1-((x1*y0)/x0))/(1-(x1/x0));
%m=(y0-b)/x0;

%above is Victor's code - I don't know why he calculated it that way

if x0 > x1
    temp = x1;
    x1 = x0;
    x0 = temp;
    temp = y1;
    y1 = y0;
    y0 = temp;
end
m = (y1-y0)/(x1-x0);
b = (y0-(m*x0));

end




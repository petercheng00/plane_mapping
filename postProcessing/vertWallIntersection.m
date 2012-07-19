function [x y] = vertWallIntersection(eq1, eq2)

%This is PeterC's wall-only version of Victor's twoPointsLine
%twoPointsLine runs into problems with zeros and NaNs for certain
%points.

%This assumes we are working with vertical walls, i.e. z-component of
%normal vectors is zero


a1= eq1(1);
a2= eq2(1);

b1= eq1(2);
b2= eq2(2);

d1= -eq1(4);
d2= -eq2(4);


yNum = d2 - (a2*d1)/a1;
yDenom = (-a2*b1)/a1 + b2;
y = yNum/yDenom;
x = (d1 - b1*y)/a1;
end
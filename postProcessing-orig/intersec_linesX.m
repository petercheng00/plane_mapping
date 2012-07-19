function [x,y] = intersec_linesX (m1,b1,m2,b2)

x=(b2-b1)/(m1-m2);

y=(m1*x)+b1;

y2=(m2*x)+b2;

end
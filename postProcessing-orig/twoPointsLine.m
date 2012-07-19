function [p1 p2] = twoPointsLine(eq1, eq2)

%find two points along the the line where two planes meet
%n1 = normal vector plane1- from plane equation
%n2 = normal vector plane 2 - from plane equation

% planes.p(1).eq
% planes.p(2).eq; 
 n1=[eq1(1) eq1(2) eq1(3)];
 n2=[eq2(1) eq2(2) eq2(3)];

lineV=cross(n1,n2);


%if z=const in both plane equations

a1= eq1(1);
a2= eq2(1);

b1= eq1(2);
b2= eq2(2);

c1= eq1(3);
c2= eq2(3);

d1= -eq1(4);
d2= -eq2(4);


z=-100;
A=d1-(c1*z);
B=d2-(c2*z);



x1=(B - ((b2/b1)*A)) / (a2- ((b2/b1)*a1));

y1= (A - (a1*x1)) / b1;
p1=[x1 y1 z];

z=100;
A=d1-(c1*z);
B=d2-(c2*z);

x2=(B - ((b2/b1)*A)) / (a2- ((b2/b1)*a1));

y2= (A - (a1*x2)) / b1;
p2=[x2 y2 z];
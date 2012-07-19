function p=newPlane(x1,x2,y1,y2,minZ,maxZ)
%Returns the delimiting points and plane equation for two points in XY and
%a min and max value for Z (following format of *.model files)

a=0;b=0;c=0;d=0;
p.npoints=4;
p.eq=[a; b; c; d];

p.x=[x1 x2 x1 x2];
p.y=[y1 y2 y1 y2];
p.z=[minZ minZ maxZ maxZ];

%Calculate planeequation (ax+by+cz+d=0)
%Pick any three delimiting points 
x1=p.x(1);
x2=p.x(2);
x3=p.x(3);
y1=p.y(1);
y2=p.y(2);
y3=p.y(3);
z1=p.z(1);
z2=p.z(2);
z3=p.z(3);


a = (y1*(z2 - z3)) + (y2*(z3 - z1)) + (y3*(z1 - z2));
b = (z1*(x2 - x3)) + (z2*(x3 - x1)) + (z3*(x1 - x2));
c = (x1*(y2 - y3)) + (x2*(y3 - y1)) + (x3*(y1 - y2));
d = -((x1*((y2*z3) - (y3*z2))) + (x2*((y3*z1) - (y1*z3))) + (x3*((y1*z2) - (y2*z1))));

fact=sqrt(a^2+b^2+c^2);

a=a/fact;
b=b/fact;
c=c/fact;
d=d/fact;


p.eq=[a; b; c; d];

end


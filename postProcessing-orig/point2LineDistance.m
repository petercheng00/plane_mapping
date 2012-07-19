function distance = point2LineDistance(p,p1,p2)

%Calculates de distance from a point p  to a line defined by points p1 and
%p2.


c1=cross( (p-p1), (p-p2));

c1Mag=sqrt(sum(c1.^2));

v2 = (p2-p1);

v2Mag=sqrt(sum(v2.^2));

distance = c1Mag/v2Mag;

end

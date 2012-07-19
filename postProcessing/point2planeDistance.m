function distance = point2planeDistance(p,eq)

%Computes the signed distance from a point p to a plane described by
%equation ax+by+cx+d=0
%eq=[a b c d]

a=eq(1);
b=eq(2);
c=eq(3);
d=eq(4);

distance =  ((a*p(1)) + (b*p(2)) + (c*p(3)) +d )/sqrt((a^2) + (b^2) +(c^2));
end
function projPt=point2Plane(p,eq)
%Project a point p=[x,y,z] onto a plane define by equation eq=[a b c d]
%ax + by + cx + d = 0

% t0 = ((eq(1)*p(1)) + (eq(2)*p(2)) + (eq(3)*p(3)) + eq(4))/sum((eq(1)^2) + (eq(2)^2) + (eq(3)^2));
% 
% projPt = [(p(1)+(eq(1)*t0)) (p(2)+(eq(2)*t0)) (p(3)+(eq(3)*t0))];

distance= point2planeDistance(p,eq);
projPt = [(p(1) - (eq(1)*distance)) (p(2) - (eq(2)*distance)) (p(3) - (eq(3)*distance))];

end
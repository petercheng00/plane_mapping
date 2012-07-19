function distance = getDistance(p1, p2)

%Compute distance between two points p1,p2 in 3D

distance = sqrt( (p1(1)-p2(1))^2 + (p1(2)-p2(2))^2  + (p1(3)-p2(3))^2 );

end
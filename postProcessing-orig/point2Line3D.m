function projPt = point2Line3D(p,p1,p2)

%Projects a point in 3D to a line in 3D
%p -  the point to be projected
%p1 - point 1 of line
%p2 - point 2 of line

lenght=sqrt( (p1(1)-p2(1))^2 +  (p1(2)-p2(2))^2 +  (p1(3)-p2(3))^2 );

unity=p2-p1;

unity=unity/lenght;

w=p-p1;

dotP = (unity(1)*w(1))+(unity(2)*w(2))+(unity(3)*w(3));

projV=(abs(dotP))*unity;

projPt=p1+projV;
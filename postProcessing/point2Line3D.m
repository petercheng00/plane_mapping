function projPt = point2Line3D(p,p1,p2)

%Projects a point in 3D to a line in 3D
%p -  the point to be projected
%p1 - point 1 of line
%p2 - point 2 of line

lenght=sqrt( (p1(1)-p2(1))^2 +  (p1(2)-p2(2))^2 +  (p1(3)-p2(3))^2 );

lineVec=p2-p1;
lineVec = lineVec/norm(lineVec);

pointVec=p-p1;

dotP = (lineVec(1)*pointVec(1))+(lineVec(2)*pointVec(2))+(lineVec(3)*pointVec(3));

projV=(dotP)*lineVec;
projPt=p1+projV;


if projPt(1) <= -100 || projPt(2) <= -100 || projPt(3) <= -100
    keyboard
end

end
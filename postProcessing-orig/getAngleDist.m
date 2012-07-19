function angle= getAngleDist(eq1, eq2)

%eq1 - the plane equation of first plane
%eq2 -  the plane equation of second wall
n1=[eq1(1) eq1(2) eq1(3)];
n2=[eq2(1) eq2(2) eq2(3)];
l1=sqrt( (eq1(1)^2) + (eq1(2)^2) + (eq1(3)^2) );
l2=sqrt( (eq2(1)^2) + (eq2(2)^2) + (eq2(3)^2) );
rad= dot(n1/l1, n2/l2);
  if rad < -1.0 
      rad = -1.0;
  end
  
  if rad >  1.0
      rad = 1.0;
  end

 angle = acos (rad);
 
 angle = min(angle, pi - rad);
 
 angle = angle*90/(pi/2);
end
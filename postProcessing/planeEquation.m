function equation = planeEquation(A,B,C)

%Use three points (A,B,C) to find plane equation

AB(1)=B(1)-A(1);
AB(2)=B(2)-A(2);
AB(3)=B(3)-A(3);

AC(1)=C(1)-A(1);
AC(2)=C(2)-A(2);
AC(3)=C(3)-A(3);



%Avoid some crashes by checking for collinearity here

dy1dy2(1)=AB(1)/AC(1);
dy1dy2(2)=AB(2)/AC(2);
dy1dy2(3)=AB(3)/AC(3);
  if ( (dy1dy2(1) == dy1dy2(2)) && (dy1dy2(3) == dy1dy2(2)) )        
    disp('Warning! collinearity');
  end


%Cross product AB X AC

n(1)=(AB(2)*AC(3)) - (AB(3)*AC(2));
n(2)=(AB(3)*AC(1)) - (AB(1)*AC(3));
n(3)=(AB(1)*AC(2)) - (AB(2)*AC(1));

%Normalize n
div= sqrt( (n(1)^2) + (n(2)^2) + (n(3)^2) );
n(1)=n(1)/div;
n(2)=n(2)/div;
n(3)=n(3)/div;

%Using point A:

equation(1)=n(1);
equation(2)=n(2);
equation(3)=n(3);
equation(4)= -1*(( n(1)*A(1) ) + ( n(2)*A(2) ) + ( n(3)*A(3)));

x1=A(1);
y1=A(2);
z1=A(3);

x2=B(1);
y2=B(2);
z2=B(3);

x3=C(1);
y3=C(2);
z3=C(3);


% a = (y1* (z2 - z3)) + (y2*(z3 - z1)) + (y3*(z1 - z2))
% b = (z1*(x2 - x3)) + (z2*(x3 - x1)) + (z3*(x1 - x2))
% c = (x1 *(y2 - y3)) + (x2*(y3 - y1)) + (x3*(y1 - y2))
% d = -( (x1 *((y2*z3) - (y3*z2))) + (x2*((y3*z1) - (y1*z3))) + (x3*((y1*z2) - (y2*z1))) )

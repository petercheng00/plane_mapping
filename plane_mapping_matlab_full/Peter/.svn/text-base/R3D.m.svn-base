function R=R3d(deg,u)
%R3D - 3D Rotation matrix counter-clockwise about an axis.
%
%R=R3d(deg,u)
%
% deg: The counter-clockwise rotation about the axis u in degrees.
%


R=eye(3);
u=u(:)/norm(u);
x=deg; %abbreviation

for ii=1:3
   
    v=R(:,ii);
    
    R(:,ii)=v*cosd(x) + cross(u,v)*sind(x) + (u.'*v)*(1-cosd(x))*u;
      %Rodrigues' formula
      
end

end 
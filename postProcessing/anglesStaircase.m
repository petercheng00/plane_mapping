
%Compute vector  of wall as projected on Z plane
%lower ramp
Wallp1=[-0.3166 4.194  0];
Wallp2=[-2.317 10.96 0];


%upper ramp
% Wallp1=[-4.667 7.145 0];
% Wallp2=[-3.662 3.342 0];


Vwall=Wallp1-Wallp2;
magVwall=sqrt(sum(Vwall.^2));

Vwall=Vwall/magVwall;


%Compute vector  of a step as projected on Z plane
%Upper ramp
%Stairp1=[-5.469 8.767 0];
%Stairp2=[-5.578 9.091 0];
%lower ramp
Stairp1=[-0.7659 6.232 0];
Stairp2=[-0.6996 5.955 0];


Vstair=Stairp2-Stairp1;
magVstair=sqrt(sum(Vstair.^2));

Vstair=Vstair/magVstair;

%Calculate angle of Vwall vector with vector [0 1 0] -- wall is mainly along
%this vector
angleWall=acos(dot(Vwall, [0 1 0]));

%Calculate angle of Vstair vector with vector [0 1 0] -- staircase is mainly along
%this vector
angleStair=acos(dot(Vstair, [0 1 0]));

%Calculate angle of Vstair vector with Vwall
angleSW=acos(dot(Vstair,Vwall));




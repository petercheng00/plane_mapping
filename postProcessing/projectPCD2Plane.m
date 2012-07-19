%Projects a point cloud  (PCD format ) into a plne defined by 
% ax + by + cz + d = 0
%Saves the projected point to file (ASCII format)

eq=[0.424405 -0.905473 0 -28.9784];

[filename, pathname] = uigetfile('*.pcd', 'Select *.pcd file', 'C:\cygwin\tmp\pcl-0.9.0\bin\');
A = dlmread([pathname filename],'\s'); 

for pt=1:1:size(A,1)
    point=[A(pt,1) A(pt,2) A(pt,3)];
    projPt=point2Plane(point,eq);
    B(pt,:)=projPt;
end
dlmwrite([pathname 'PROJ_' filename], B,  '\s');



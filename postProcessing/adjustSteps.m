function adjustSteps(p1,p2,p3, p4)

%Adjusts the width of steps using the lines defined by p1, p2 and by p3,p4 as a basis


%Increase length of lines
%Line1
 [m1,b1]=line_param(p1(1),p2(1),p1(2),p2(2));
 
 if p1(1)>p2(1)
     p1(1)=100000;
     p1(2)=(m1*p1(1))+b1;
     
     p2(1)=-100000;
     p2(2)=(m1*p2(1))+b1;
     
 end
 
  if p1(1)<p2(1)
     p1(1)=-100000;
     p1(2)=(m1*p1(1))+b1;
     
     p2(1)=100000;
     p2(2)=(m1*p2(1))+b1;
     
  end
 
  %line2
   [m2,b2]=line_param(p3(1),p4(1),p3(2),p4(2));
 
 if p3(1)>p4(1)
     p3(1)=100000;
     p3(2)=(m2*p3(1))+b2;
     
     p4(1)=-100000;
     p4(2)=(m2*p4(1))+b2;
     
 end
 
  if p3(1)<p4(1)
     p3(1)=-100000;
     p3(2)=(m2*p3(1))+b2;
     
     p4(1)=100000;
     p4(2)=(m2*p4(1))+b2;
     
  end
 

%Read model file containing the steps
[filename, pathname] = uigetfile('*.model', 'Select *.model file containing steps', 'C:\cygwin\tmp\pcl-0.9.0\bin\');
fid = fopen([pathname filename]);
A = fscanf(fid, '%f', [inf]);
fclose(fid);

tot_planes = A(1,1);
pointer=2;
planes.tot=tot_planes;


for cplane=1:1:tot_planes

    planes.p(cplane).npoints= A(pointer,1); %Get number of points delimiting current plane
    pointer=pointer+1;

    planes.p(cplane).eq=A(pointer:pointer+3,1); %Get equation describing current plane
    pointer=pointer+4;

    cpoint=1;
    for x=1:1:planes.p(cplane).npoints %Get the points delimiting plane
        planes.p(cplane).x(cpoint)=A(pointer,1);
        planes.p(cplane).y(cpoint)=A(pointer+1,1);
        planes.p(cplane).z(cpoint)=A(pointer+2,1);
        
        %Compute distances of delimintg points of each step to line defined by
        %p1,p2
        
        p=[planes.p(cplane).x(cpoint)  planes.p(cplane).y(cpoint) 0];%make Z component 0, i.e., porjected point to Z-plane
        distance= point2LineDistance(p,p1,p2);
        planes.p(cplane).distance1(cpoint)=distance; %store distance
        
        %Compute distances of delimintg points of each step to line defined by
        %p3,p4
        
        p=[planes.p(cplane).x(cpoint)  planes.p(cplane).y(cpoint) 0];%make Z component 0, i.e., porjected point to Z-plane
        distance= point2LineDistance(p,p3,p4);
        planes.p(cplane).distance2(cpoint)=distance; %store distance

        cpoint=cpoint+1;
        pointer=pointer+3;
    end
    
    %Adust using line defined by p1,p2
    [D,I]=sort(planes.p(cplane).distance1); %Sort distances and pick the two smallest
    
    pA=[planes.p(cplane).x(I(1))  planes.p(cplane).y(I(1)) 0];%make Z component 0, i.e., projected point to Z-plane
    pB=[planes.p(cplane).x(I(2))  planes.p(cplane).y(I(2)) 0];%make Z component 0, i.e., projected point to Z-plane
    
    projPtA = point2Line3D(pA,p1,p2);%Project points to line
    projPtB = point2Line3D(pB,p1,p2);
    
    planes.p(cplane).x(I(1)) =  projPtA(1); %store projected point in structure
    planes.p(cplane).y(I(1)) = projPtA(2);
    
    planes.p(cplane).x(I(2)) =  projPtB(1); %store projected point in structure
    planes.p(cplane).y(I(2)) = projPtB(2);
    
    %Adust using line defined by p3,p4
    [D,I]=sort(planes.p(cplane).distance2); %Sort distances and pick the two smallest
    
    pA=[planes.p(cplane).x(I(1))  planes.p(cplane).y(I(1)) 0];%make Z component 0, i.e., projected point to Z-plane
    pB=[planes.p(cplane).x(I(2))  planes.p(cplane).y(I(2)) 0];%make Z component 0, i.e., projected point to Z-plane
    
    projPtA = point2Line3D(pA,p3,p4);%Project points to line
    projPtB = point2Line3D(pB,p3,p4);
    
    planes.p(cplane).x(I(1)) =  projPtA(1); %store projected point in structure
    planes.p(cplane).y(I(1)) = projPtA(2);
    
    planes.p(cplane).x(I(2)) =  projPtB(1); %store projected point in structure
    planes.p(cplane).y(I(2)) = projPtB(2);
    

end


    %Save the adjusted steps
    fid2 = fopen([pathname  'ADJ_' filename ], 'wt');
    fprintf(fid, '%i\n',planes.tot); %Total number of planes
    pointer=2;
    tot_planes=planes.tot;

    for cplane=1:1:tot_planes

        fprintf(fid, '%i\n',planes.p(cplane).npoints); %Save number of points delimiting current plane
        fprintf(fid, '%f %f %f %f\n', planes.p(cplane).eq(1,1), planes.p(cplane).eq(2,1),planes.p(cplane).eq(3,1),planes.p(cplane).eq(4,1)); %Save equation describing current plane

        for cpoint=1:1:planes.p(cplane).npoints %Save the points delimiting plane
            fprintf(fid, '%f %f %f\n',planes.p(cplane).x(cpoint), planes.p(cplane).y(cpoint),planes.p(cplane).z(cpoint));
        end

    end

fclose('all');

end
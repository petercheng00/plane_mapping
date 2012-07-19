function fillCorners3(th, th2)

%PeterC's version of fillCorners2
%This version fixes a couple bugs related to edge cases and also fits
%planes together in T-junctions.

%This functions takes a *.model file as input and returns a *.model file
%with all walls touching each other at the corners

%th - threshold to find adjacent walls in X,Y direction
%th2 - threshold to find adjacent walls in Z direction

[filename, pathname] = uigetfile('*.model', 'Select *.model file', 'C:\cygwin\tmp\pcl-0.9.0\bin\');
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
        cpoint=cpoint+1;
        pointer=pointer+3;
    end
 
end
%Divide walls into two sets 
wallsX=[];
wallsY=[];
for cplane=1:1:tot_planes
    
    if (abs(planes.p(cplane).eq(1))>abs(planes.p(cplane).eq(2))) && (abs(planes.p(cplane).eq(1))>abs(planes.p(cplane).eq(3))) %A wall with stron X-normal component
        wallsX=[wallsX; cplane];
    end
    
    if (abs(planes.p(cplane).eq(2))>abs(planes.p(cplane).eq(1))) && (abs(planes.p(cplane).eq(2))>abs(planes.p(cplane).eq(3))) %A wall with stron Y-normal component
        wallsY=[wallsY; cplane];
    end

end


%Pair up wallsX with wallsY if they are close enough to each other, either
%a corner or a t-junction
for wall=1:1:size(wallsX,1)
    wall;

    
    for wallp=1:1:size(wallsY,1)
        wallp;
        
        cplane=wallsX(wall);
        cplaneY=wallsY(wallp);        
        
        maxZ = max(planes.p(cplane).z);
        maxZ2 = max(planes.p(claneY).z);
        minZ = min(planes.p(cplane).z);
        minZ2 = min(planes.p(cplaneY).z);
        
        if abs(maxZ2-maxZ) > th2 || abs(minZ2-minZ) > th2
            continue;
        end
        
        
        [x y]=vertWallIntersection(planes.p(cplane).eq, planes.p(cplaneY).eq);
        
        pointer=find(planes.p(cplane).y==minY);
        minYPoint=[planes.p(cplane).x(pointer(1)), minY];
            
        pointer=find(planes.p(cplane).y==maxY);
        maxYPoint=[planes.p(cplane).x(pointer(1)), maxY];
        
        pointer=find(planes.p(cplaneY).y==minY2);
        minY2Point=[planes.p(cplaneY).x(pointer(1)), minY2];
            
        pointer=find(planes.p(cplaneY).y==maxY2);
        maxY2Point=[planes.p(cplaneY).x(pointer(1)), maxY2];        
        
        points1 = [minYPoint;maxYPoint];
        points2 = [minY2Point;maxY2Point];
        distances1 = sqrt((points1(:,1) - x)^2 + (points1(:,2) - y)^2);
        distances2 = sqrt((points2(:,1) - x)^2 + (points2(:,2) - y)^2);
        
        minDist1, minInd1 = min(distances1);
        minDist2, minInd2 = min(distances2);
        if minDist1 <= th
            %extend plane 1 to intersection line
            if minInd1 == 1
                val = minY;
            else
                val = maxY;
            end
            
            
            pointer = find(planes.p(cplane).y==val); % points with same maxY values in cplane        
            for k=1:1:size(pointer,2)
                p=[planes.p(cplane).x(pointer(k)) planes.p(cplane).y(pointer(k)) planes.p(cplane).z(pointer(k))];
                projPt = point2Line3D(p,p1,p2);
                %replace points with porjected ones
                planes.p(cplane).x(pointer(k))=projPt(1);
                planes.p(cplane).y(pointer(k))=projPt(2);
                if projPt(3)~= planes.p(cplane).z(pointer(k))
                    disp('Adjusting z');
                end
                    %planes.p(cplane).z(pointer(k))=projPt(3);
            end
            
        end
        if minDist2 <= th
            %extend plane 1 to intersection line
            if minInd2 == 1
                val = minY2;
            else
                val = maxY2;
            end
            
            
            pointer = find(planes.p(cplaneY).y==val); % points with same maxY values in cplane        
            for k=1:1:size(pointer,2)
                p=[planes.p(cplaneY).x(pointer(k)) planes.p(cplaneY).y(pointer(k)) planes.p(cplaneY).z(pointer(k))];
                projPt = point2Line3D(p,p1,p2);
                %replace points with porjected ones
                planes.p(cplaneY).x(pointer(k))=projPt(1);
                planes.p(cplaneY).y(pointer(k))=projPt(2);
                if projPt(3)~= planes.p(cplaneY).z(pointer(k))
                    disp('Adjusting z');
                end
                    %planes.p(cplane).z(pointer(k))=projPt(3);
            end
            
        end
        

        
          
    end

end

    

fid2 = fopen([pathname  'F_' filename ], 'wt');
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

fclose(fid2);

figure;

for cplane=1:1:tot_planes


        vert=[planes.p(cplane).x', planes.p(cplane).y',planes.p(cplane).z']; 
        fac=[1:1:planes.p(cplane).npoints];
        patch('vertices', vert,'faces',fac,'facecolor',[(cplane/(tot_planes*2)) (cplane/tot_planes) (cplane/tot_planes)]); hold on;
        view(3); 
        daspect([1 1 1]);
        axis('tight');
        disp('Press any key to continue');
        pause    

end

    
   
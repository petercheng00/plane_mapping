function fillCorners3(th, th2)

%PeterC's version of fillCorners2
%This version fixes a couple bugs related to edge cases and also fits
%planes together in T-junctions.

%This functions takes a *.model file as input and returns a *.model file
%with all walls touching each other at corners or T-junctions

%th - threshold to find adjacent walls in X,Y direction
%th2 - threshold to find adjacent walls in Z direction

[filename, pathname] = uigetfile('*.model', 'Select *.model file');
fid = fopen([pathname filename]);
A = fscanf(fid, '%f', [inf]);
fclose(fid);

tot_planes = A(1,1);
pointer=2;
planes.tot=tot_planes;


wallsX = [];
wallsY = [];

for currPlane=1:1:tot_planes

    planes.p(currPlane).npoints= A(pointer,1); %Get number of points delimiting current plane
    pointer=pointer+1;

    planes.p(currPlane).eq=A(pointer:pointer+3,1); %Get equation describing current plane
    pointer=pointer+4;

    for cpoint=1:planes.p(currPlane).npoints %Get the points delimiting plane
        planes.p(currPlane).x(cpoint)=A(pointer,1);
        planes.p(currPlane).y(cpoint)=A(pointer+1,1);
        planes.p(currPlane).z(cpoint)=A(pointer+2,1);
        pointer=pointer+3;
    end
	
	if (abs(planes.p(currPlane).eq(1))>abs(planes.p(currPlane).eq(2))) && (abs(planes.p(currPlane).eq(1))>abs(planes.p(currPlane).eq(3))) %A wall with stron X-normal component
        wallsX=[wallsX; currPlane];
    end
    
    if (abs(planes.p(currPlane).eq(2))>abs(planes.p(currPlane).eq(1))) && (abs(planes.p(currPlane).eq(2))>abs(planes.p(currPlane).eq(3))) %A wall with stron Y-normal component
        wallsY=[wallsY; currPlane];
    end

 
end


%Pair up wallsX with wallsY if they are close enough to each other, either
%a corner or a t-junction
for wallXInd=1:1:size(wallsX,1)
    
    for wallYInd=1:1:size(wallsY,1)
        
        currPlaneX=wallsX(wallXInd);
        currPlaneY=wallsY(wallYInd);        
        
        maxY = max(planes.p(currPlaneX).y);
        minY = min(planes.p(currPlaneX).y);
        
        maxX = max(planes.p(currPlaneY).x);
        minX = min(planes.p(currPlaneY).x);
        
        maxZ = max(planes.p(currPlaneX).z);
        maxZ2 = max(planes.p(currPlaneY).z);
        minZ = min(planes.p(currPlaneX).z);
        minZ2 = min(planes.p(currPlaneY).z);
        
        %if abs(maxZ2-maxZ) > th2 || abs(minZ2-minZ) > th2
        %    continue;
        %end
        
        
        [intersectX intersectY]=vertWallIntersection(planes.p(currPlaneX).eq, planes.p(currPlaneY).eq);
        
        pointer=find(planes.p(currPlaneX).y==minY);
        minYPoint=[planes.p(currPlaneX).x(pointer(1)), minY];
            
        pointer=find(planes.p(currPlaneX).y==maxY);
        maxYPoint=[planes.p(currPlaneX).x(pointer(1)), maxY];
        
        pointer=find(planes.p(currPlaneY).x==minX);
        minXPoint=[minX, planes.p(currPlaneY).y(pointer(1))];
            
        pointer=find(planes.p(currPlaneY).x==maxX);
        maxXPoint=[maxX, planes.p(currPlaneY).y(pointer(1))];        
        
        %valid cases to join
        %corner: p1 is near intersection, p2 is near intersection
        %t-junction: p1 is near intersection, intersection inside other
        %plane
        
        
        pointsPlaneX = [minYPoint;maxYPoint];
        pointsPlaneY = [minXPoint;maxXPoint];
        
        distancesPlaneX = sqrt((pointsPlaneX(:,1) - intersectX).^2 + (pointsPlaneX(:,2) - intersectY).^2);
        distancesPlaneY = sqrt((pointsPlaneY(:,1) - intersectX).^2 + (pointsPlaneY(:,2) - intersectY).^2);
        
        inBetweenPlaneX = minY <= intersectY && intersectY <= maxY;
        inBetweenPlaneY = minX <= intersectX && intersectX <= maxX;
        
        minDistPlaneX = th+1;
        yVal = -1;
        minDistPlaneY = th+1;
        xVal = -1;
        if distancesPlaneX(1) <= th && ((min(distancesPlaneY) <= th) || inBetweenPlaneY)
            minDistPlaneX = distancesPlaneX(1);
            yVal = minY;
        end
        if distancesPlaneX(2) <= min(th, minDistPlaneX) && ((min(distancesPlaneY) <= th) || inBetweenPlaneY)
            minDistPlaneX = distancesPlaneX(2);
            yVal = maxY;
        end
        if distancesPlaneY(1) <= th && ((min(distancesPlaneX) <= th) || inBetweenPlaneX)
            minDistPlaneY = distancesPlaneY(1);
            xVal = minX;
        end
        if distancesPlaneY(2) <= min(th, minDistPlaneY) && ((min(distancesPlaneX) <= th) || inBetweenPlaneX)
            minDistPlaneY = distancesPlaneY(2);
            xVal = maxX;
        end
        
        
        if minDistPlaneX <= th
            %extend plane 1 to intersection line

            
            pointer = find(planes.p(currPlaneX).y==yVal);  
            for k=1:1:size(pointer,2)
                p=[planes.p(currPlaneX).x(pointer(k)) planes.p(currPlaneX).y(pointer(k)) planes.p(currPlaneX).z(pointer(k))];
                p1 = [intersectX, intersectY, -100];
                p2 = [intersectX, intersectY, 100];
                projPt = point2Line3D(p,p1,p2);
                %replace points with projected ones
                planes.p(currPlaneX).x(pointer(k))=projPt(1);
                planes.p(currPlaneX).y(pointer(k))=projPt(2);
                %if projPt(3)~= planes.p(currPlaneX).z(pointer(k))
                %    disp('Adjusting z');
                %end
                %planes.p(currPlaneX).z(pointer(k))=projPt(3);
            end
            
        end
        if minDistPlaneY <= th
            %extend plane 1 to intersection line
            
            
            pointer = find(planes.p(currPlaneY).x==xVal);
            for k=1:1:size(pointer,2)
                p=[planes.p(currPlaneY).x(pointer(k)) planes.p(currPlaneY).y(pointer(k)) planes.p(currPlaneY).z(pointer(k))];
                p1 = [intersectX, intersectY, -100];
                p2 = [intersectX, intersectY, 100];
                projPt = point2Line3D(p,p1,p2);
                %replace points with projected ones
                planes.p(currPlaneY).x(pointer(k))=projPt(1);
                planes.p(currPlaneY).y(pointer(k))=projPt(2);
                %if projPt(3)~= planes.p(currPlaneXY).z(pointer(k))
                %    disp('Adjusting z');
                %end
                %planes.p(currPlaneX).z(pointer(k))=projPt(3);
            end
            
        end
        

        
          
    end

end

    

fid2 = fopen([pathname  'F_' filename ], 'wt');
fprintf(fid, '%i\n',planes.tot); %Total number of planes
pointer=2;
tot_planes=planes.tot;

for currPlaneX=1:1:tot_planes

    fprintf(fid, '%i\n',planes.p(currPlaneX).npoints); %Save number of points delimiting current plane
    fprintf(fid, '%f %f %f %f\n', planes.p(currPlaneX).eq(1,1), planes.p(currPlaneX).eq(2,1),planes.p(currPlaneX).eq(3,1),planes.p(currPlaneX).eq(4,1)); %Save equation describing current plane

    for cpoint=1:1:planes.p(currPlaneX).npoints %Save the points delimiting plane
        fprintf(fid, '%f %f %f\n',planes.p(currPlaneX).x(cpoint), planes.p(currPlaneX).y(cpoint),planes.p(currPlaneX).z(cpoint));
    end
    
end

fclose(fid2);

figure;

for currPlaneX=1:1:tot_planes

    if planes.p(currPlaneX).eq(3) == 0
        vert=[planes.p(currPlaneX).x', planes.p(currPlaneX).y',planes.p(currPlaneX).z']; 
        fac=[1:1:planes.p(currPlaneX).npoints];
        patch('vertices', vert,'faces',fac,'facecolor',[(currPlaneX/(tot_planes*2)) (currPlaneX/tot_planes) (currPlaneX/tot_planes)]); hold on;
        view(3); 
        daspect([1 1 1]);
        axis('tight');
        disp('Press any key to continue');
        pause    
    end

end

    
   
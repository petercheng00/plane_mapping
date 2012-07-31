function fillCorners3D(th, th2)

%PeterC's attempt to unify scripts by just rotating ceilings and floors so
%that they become walls. Doesn't quite work well yet.
%so don't use this

error 'dont use this'

[filename, pathname] = uigetfile('*.model', 'Select *.model file');
fid = fopen([pathname filename]);
A = fscanf(fid, '%f', [inf]);
fclose(fid);


tot_planes = A(1,1);
pointer=2;
planes.tot=tot_planes;

for currPlane=1:1:tot_planes

	planes.p(currPlane).npoints= A(pointer,1); %Get number of points delimiting current plane
	pointer=pointer+1;

	planes.p(currPlane).eq=A(pointer:pointer+3,1); %Get equation describing current plane
	pointer=pointer+4;

	for cpoint=1:planes.p(currPlane).npoints %Get the points delimiting plane
		planes.p(currPlane).x(cpoint) = A(pointer,1);
		planes.p(currPlane).y(cpoint) = A(pointer+1,1);
		planes.p(currPlane).z(cpoint) = A(pointer+2,1);
		pointer=pointer+3;
	end
 
end

rotationAxis1 = [1,0,0];
rotationAxis2 = [0,1,0];
rotationAngle = 90;
R1 = R3D(rotationAngle, rotationAxis1);
R2 = R3D(rotationAngle, rotationAxis2);

for iter = 1:3
    
    wallsX = [];
	wallsY = [];
    
    rotation = eye(3);
	if iter == 2
		rotation = R1;
    elseif iter == 3
		rotation = R2;
    end
    
	for currPlane=1:1:tot_planes
		unRotated = [planes.p(currPlane).x; planes.p(currPlane).y; planes.p(currPlane).z];
		rotated = rotation * unRotated;
		planes.p(currPlane).x = rotated(1,:);
		planes.p(currPlane).y = rotated(2,:);
		planes.p(currPlane).z = rotated(3,:);	 
		planes.p(currPlane).eq(1:3) = rotation * planes.p(currPlane).eq(1:3);
		
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
	
	for currPlane=1:1:tot_planes
		rotated = [planes.p(currPlane).x; planes.p(currPlane).y; planes.p(currPlane).z];
		unRotated = rotation' * rotated;
		planes.p(currPlane).x = unRotated(1,:);
		planes.p(currPlane).y = unRotated(2,:);
		planes.p(currPlane).z = unRotated(3,:);	 
		
		planes.p(currPlane).eq(1:3) = rotation' * planes.p(currPlane).eq(1:3);
	end

end    


fid2 = fopen([pathname  'F_' filename ], 'wt');
fprintf(fid, '%i\n',planes.tot); %Total number of planes
pointer=2;
tot_planes=planes.tot;

for currPlane=1:1:tot_planes

    fprintf(fid, '%i\n',planes.p(currPlane).npoints); %Save number of points delimiting current plane
    fprintf(fid, '%f %f %f %f\n', planes.p(currPlane).eq(1,1), planes.p(currPlane).eq(2,1),planes.p(currPlane).eq(3,1),planes.p(currPlane).eq(4,1)); %Save equation describing current plane

    for cpoint=1:1:planes.p(currPlane).npoints %Save the points delimiting plane
        fprintf(fid, '%f %f %f\n',planes.p(currPlane).x(cpoint), planes.p(currPlane).y(cpoint),planes.p(currPlane).z(cpoint));
    end
    
end

fclose(fid2);

figure;

for currPlane=1:1:tot_planes
    
        vert=[planes.p(currPlane).x', planes.p(currPlane).y',planes.p(currPlane).z']; 
        fac=[1:1:planes.p(currPlane).npoints];
        patch('vertices', vert,'faces',fac,'facecolor',[(currPlane/(tot_planes*2)) (currPlane/tot_planes) (currPlane/tot_planes)]); hold on;
        view(3); 
        daspect([1 1 1]);
        axis('tight');
        disp('Press any key to continue');
        pause    

end

    
   
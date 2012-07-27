function fillCFWalls4(th1, th2)

%This functions takes a *.model file as input and returns a *.model file
%with each wall touching its respective "best" ceiling and floor

%Intended to replace Victor's fillCFWalls3/fillCFWalls3b/fillCFWalls3c

%This script however

%th- distance threshold between a celilng/floor and a wall (in Z direction)
%th2 -distance threshold to smooth edges of ceiling floor following walls


[filename, pathname] = uigetfile('*.model', 'Select *.model file');
fid = fopen([pathname filename]);
A = fscanf(fid, '%f', inf);
fclose(fid);

tot_planes = A(1,1);
pointer=2;
planes.tot=tot_planes;

%Divide planes into two sets
CFInd = false(tot_planes);
wallsInd = false(tot_planes);

for currPlane=1:tot_planes
    
    planes.p(currPlane).npoints= A(pointer,1); %Get number of points delimiting current plane
    pointer=pointer+1;
    
    planes.p(currPlane).eq=A(pointer:pointer+3,1); %Get equation describing current plane
    pointer=pointer+4;
    
    cpoint=1;
    for x=1:1:planes.p(currPlane).npoints %Get the points delimiting plane
        planes.p(currPlane).x(cpoint)=A(pointer,1);
        planes.p(currPlane).y(cpoint)=A(pointer+1,1);
        planes.p(currPlane).z(cpoint)=A(pointer+2,1);
        cpoint=cpoint+1;
        pointer=pointer+3;
    end
    
    if ((abs(planes.p(currPlane).eq(1))==0) && (abs(planes.p(currPlane).eq(2))==0)) %A ceiling or floor
        CFInd(currPlane) = 1;
    else
        wallsInd(currPlane) = 1;
    end
    
end



CF = find(CFInd);
walls = find(wallsInd);


for wallInd = 1:size(walls)
    currWall = planes.p(walls(wallInd));
    matchToCeiling = false;
    matchToFloor = false;
    
    currWall_maxZ = max(currWall.z);
    currWall_minZ = min(currWall.z);
    
    maxZInds = find((currWall.z == currWall_maxZ));
    minZInds = find((currWall.z == currWall_minZ));
    
    %both equations should be the same really.
    if size(maxZInds,2) >= 2
        matchToCeiling = true;
        ind1 = 1;
        ind2 = 2;
        while ((currWall.x(maxZInds(ind1)) == currWall.x(maxZInds(ind2))) && currWall.y(maxZInds(ind1)) == currWall.y(maxZInds(ind2)))
            ind2 = ind2 + 1;
        end
        [maxZeq_m, maxZeq_b] = line_param(currWall.x(maxZInds(ind1)),currWall.x(maxZInds(ind2)),currWall.y(maxZInds(ind1)),currWall.y(maxZInds(ind2)));
    end
    if size(minZInds,2) >= 2
        matchToFloor = true;
        ind1 = 1;
        ind2 = 2;
        while (currWall.x(minZInds(ind1)) == currWall.x(minZInds(ind2))) && currWall.y(minZInds(ind1)) == currWall.y(minZInds(ind2))
            ind2 = ind2 + 1;
        end
        [minZeq_m, minZeq_b] = line_param(currWall.x(minZInds(ind1)),currWall.x(minZInds(ind2)),currWall.y(minZInds(ind1)),currWall.y(minZInds(ind2)));
    end
    
    
    bestCeilingInd = 0;
    bestFloorInd = 0;
    bestCeilingRange = 0;
    bestFloorRange = 0;
    bestCeilingNearVerts = [];
    bestFloorNearVerts = [];
    
    for CFInd = 1:size(CF)
        currCF = planes.p(CF(CFInd));
        if matchToCeiling && abs(currCF.z(1) - currWall_maxZ) <= th1
            %this CF is looking more like a C
            isCeiling = true;
            wallEQ_m = maxZeq_m;
            wallEQ_b = maxZeq_b;
        elseif matchToFloor && abs(currCF.z(1) - currWall_minZ) <= th1
            %floor
            isCeiling = false;
            wallEQ_m = minZeq_m;
            wallEQ_b = minZeq_b;
        else
            continue;
        end
        
        %grab CF vertices that are contained within the wall's span and
        %also near its 2d line
        nearCFVertInds = false(1,currCF.npoints);
        for CFvertInd=1:currCF.npoints
            A=wallEQ_m;
            B=-1;
            C=wallEQ_b;
            d=abs(( A*currCF.x(CFvertInd)) + (B*currCF.y(CFvertInd)) + C)/sqrt((A^2)+(B^2));
            if isCeiling && withinRange(currCF.x(CFvertInd),currCF.y(CFvertInd),currWall.x(maxZInds),currWall.y(maxZInds),th2) && d <= th2
                nearCFVertInds(CFvertInd) = 1;
            end
            if ~isCeiling && withinRange(currCF.x(CFvertInd),currCF.y(CFvertInd),currWall.x(minZInds),currWall.y(minZInds),th2) && d <= th2
                nearCFVertInds(CFvertInd) = 1;
            end
        end
        nearCFVerts = find(nearCFVertInds);
        %need at least 2 to be worth projecting
        if size(nearCFVerts,2) < 2
            continue;
        end
        
        %now find the max range spanned by these near verts
        %assume things are simple, so we can just use first and last vertex
        nearCFVertRange = sqrt((max(currCF.x(nearCFVerts)) - min(currCF.x(nearCFVerts)))^2 + ...
            (max(currCF.y(nearCFVerts())) - min(currCF.y(nearCFVerts)))^2);
        if isCeiling && nearCFVertRange > bestCeilingRange
            bestCeilingInd = CFInd;
            bestCeilingRange = nearCFVertRange;
            bestCeilingNearVerts = nearCFVerts;
        elseif ~isCeiling && nearCFVertRange > bestFloorRange
            bestFloorInd = CFInd;
            bestFloorRange = nearCFVertRange;
            bestFloorNearVerts = nearCFVerts;
        end
    end
    
    if bestCeilingInd == 0 && bestFloorInd == 0
        continue;
    end
    
    %extend wall to meet ceiling and floor
    %also project best ceiling and floor vertices to meet wall line
    %this results in unnecessary vertices. For now, leaving them in. They
    %can be removed by running the fixModelFile script.
    if bestCeilingInd ~= 0
        bestCeiling = planes.p(CF(bestCeilingInd));
        ceilingZ = bestCeiling.z(1);
        currWall.z(maxZInds) = repmat(ceilingZ, size(maxZInds));
        line_p1 = [0,maxZeq_b,ceilingZ];
        line_p2 = [1,maxZeq_b + maxZeq_m, ceilingZ];
        for i = 1:size(bestCeilingNearVerts,2)
            vertInd = bestCeilingNearVerts(i);
            currVert = [bestCeiling.x(vertInd), bestCeiling.y(vertInd), bestCeiling.z(vertInd)];
            projectedVert = point2Line3D(currVert, line_p1, line_p2);
            bestCeiling.x(vertInd) = projectedVert(1);
            bestCeiling.y(vertInd) = projectedVert(2);
            bestCeiling.z(vertInd) = projectedVert(3);
        end
        planes.p(CF(bestCeilingInd)) = bestCeiling;
    end
    if bestFloorInd ~= 0
        bestFloor = planes.p(CF(bestFloorInd));
        floorZ = bestFloor.z(1);
        currWall.z(minZInds) = repmat(planes.p(CF(bestFloorInd)).z(1), size(minZInds));
        line_p1 = [0,minZeq_b,floorZ];
        line_p2 = [1,minZeq_b + minZeq_m, floorZ];
        for i = 1:size(bestFloorNearVerts,2)
            vertInd = bestFloorNearVerts(i);
            currVert = [bestFloor.x(vertInd), bestFloor.y(vertInd), bestFloor.z(vertInd)];
            projectedVert = point2Line3D(currVert, line_p1, line_p2);
            bestFloor.x(vertInd) = projectedVert(1);
            bestFloor.y(vertInd) = projectedVert(2);
            bestFloor.z(vertInd) = projectedVert(3);
        end
        planes.p(CF(bestFloorInd)) = bestFloor;
    end
    
    
    
    
    planes.p(walls(wallInd)) = currWall;
end



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
end




function within = withinRange(testX, testY, vertsX, vertsY, th)
    within = ~(testX > (max(vertsX)+th) || testX < (min(vertsX)-th) || ...
            testY > (max(vertsY)+th) || testY < (min(vertsY)-th));
end






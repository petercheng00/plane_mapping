function newPlanes = divide2DPlane(plane, scoreThreshold, diffThreshold)
%input vertices are in 3D, but the zVals should all be the same, aka a horizontal plane
    
    triangles = earClipping(plane);
    %sort the triangles biggest to smallest
    triangleAreas = zeros(1,size(triangles,2));
    for i = 1:size(triangleAreas,2)
        triangleAreas(i) = triangleArea(triangles(i).vertices);
    end
    [~, I] = sort(triangleAreas);
    triangles = triangles(I);

    %this is for just doing triangulation and debugging ear clipping
    %newPlanes = triangles;
    %for i = 1:size(newPlanes,2)
    %    newPlanes(i).numVertices = 3;
    %    newPlanes(i).equation = [0,0,0,1];
    %end
    %return

    
    newPlanes = [];

	%for triangleIds:
    %0 means used
    %1 is default
    %2 means selected for current polygon
    %3 means current adjacents

    triangleIds = ones(1,size(triangles,2));
    while sum(triangleIds) > 0
        %pick a triangle to start with
        currId = find(triangleIds == 1);
        triangleIds(currId(1)) = 2;
        oldScore = 0;
        while(true)
            candidateIds = find(triangleIds == 1 | triangleIds == 3);
            if size(candidateIds,2) == 0
                break;
            end
            bestScore = -1;
            bestAdjacent = -1;
            for i = 1:size(candidateIds,2);
                if triangleIds(candidateIds(i)) == 3 || isAdjacent(triangles(triangleIds==2), triangles(candidateIds(i)))
                    triangleIds(candidateIds(i)) = 3;
                    currScore = calculateScore([triangles(triangleIds ==2), triangles(candidateIds(i))]);
                    if currScore > bestScore
                        bestScore = currScore;
                        bestAdjacent = candidateIds(i);
                    end
                end
            end
            if bestScore > scoreThreshold && (oldScore == 0 || oldScore - bestScore < diffThreshold)
                triangleIds(bestAdjacent) = 2;
                oldScore = bestScore;
            else
                if bestScore < scoreThreshold
                    disp('did not meet score Thresh');
                else
                    disp('did not meet diff Thresh');
                end
                break;
            end
            
        end
        usedIds = triangleIds == 2;
        adjacentIds = triangleIds == 3;
        newPlanes = [newPlanes, makePlaneFrom(triangles(usedIds), plane)];
        triangleIds(usedIds) = 0;
        triangleIds(adjacentIds) = 1;
    end
end

function score = calculateScore(triangles)
    %first get sum of areas of triangles. all triangles should be connected.
    polygonArea = 0;
    allVertices = zeros(size(triangles,2)*3,3);
    for i = 1:size(triangles,2)
        polygonArea = polygonArea + triangleArea(triangles(i).vertices);
        j = ((i-1)*3) + 1;
        allVertices(j:j+2,:) = triangles(i).vertices;
    end

    %next get area of bounding box.
    minBB = minBoundingBox(allVertices(:,1:2)');
    bbArea = norm(cross([(minBB(:,2) - minBB(:,1));0], [(minBB(:,3) - minBB(:,2));0]));
    score = polygonArea / bbArea;
end

function [adjacent, shared1, shared2, notShared] = isAdjacent(triangles, candidate)
	adjacent = false;
    shared1 = -1;
    shared2 = -1;
    notShared = -1;
	for i = 1:size(triangles,2)
    	numMatch = 0;
		for j = 1:size(triangles(i).vertices,1)
			for k = 1:size(candidate.vertices,1)
				if isequal(triangles(i).vertices(j,:), candidate.vertices(k,:))
					if numMatch == 0
						numMatch = 1;
						shared1 = candidate.vertices(k,:);
					elseif numMatch == 1
						shared2 = candidate.vertices(k,:);
						numMatch = 2;
						adjacent = true;
                        break;
                    end
				end
			end
			if numMatch == 2
				break;
			end
		end
		if numMatch == 2
			break;
		end
    end
    if adjacent
        for i = 1:size(candidate.vertices,1)
            if ~isequal(shared1, candidate.vertices(i,:)) && ~isequal(shared2, candidate.vertices(i,:))
                notShared = candidate.vertices(i,:);
            end
        end
    end
end
	

function area = triangleArea(t)
    a = t(1,1) * (t(2,2) - t(3,2));
    b = t(2,1) * (t(3,2) - t(1,2));
    c = t(3,1) * (t(1,2) - t(2,2));
    area = abs((a + b + c) / 2);
end

function plane = makePlaneFrom(triangles, refPlane)
	%build a polygon by iteratively adding triangles together.
	usedTriangles = triangles(1);
	vertices = triangles(1).vertices;
	triangles = triangles(2:end);
	while size(triangles,2) > 0
		for i = 1:size(triangles,2)
			[adjacent, shared1, shared2, notShared] = isAdjacent(usedTriangles, triangles(i));
			if adjacent
				%find out where to insert the new vertex
				for j = 1:size(vertices,1)
					k = j+1;
					if k == size(vertices,1) + 1
						k = 1;
					end
					if ((isequal(vertices(j,:), shared1) && isequal(vertices(k,:), shared2)) || ...
                            isequal(vertices(j,:), shared2) && isequal(vertices(k, :), shared1))
						vertices = [vertices(1:j,:);notShared;vertices(j+1:end,:)];
                    end
                end
                usedTriangles = [usedTriangles, triangles(i)];                
				triangles = [triangles(1:i-1),triangles(i+1:end)];
				break;
			end
		end
	end
	plane.vertices = vertices;
	plane.numVertices = size(vertices,1);
	plane.equation = refPlane.equation;
end
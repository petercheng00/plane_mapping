 function [bbCorners,relCoords] = calculate_bounding_box(vertices,normal)
    % Rotate the plane such that it has a constant Z value (R1) and optimal
    % bounding box is axis aligned (R2)

    upVect = [0, 0, 1];
    if normal(1) == 0 && normal(2) == 0 && (normal(3) == 1 || normal(3) == -1)
        % plane is already flat, so R1 is just identity.
        R1 = eye(3);
        rotatedVertices = vertices;
    else
        rotationAxis = cross(normal, upVect);
        rotationAngle = acosd(dot(normal, upVect)/norm(normal)/norm(upVect));

        %first rotate to make plane flat
        R1 = R3D(rotationAngle, rotationAxis);
        rotatedVertices = (R1 * vertices')';
    end

    optimalBB = (minBoundingBox((rotatedVertices(:,1:2))'))';
    xDist = optimalBB(2,1) - optimalBB(1,1);
    yDist = optimalBB(2,2) - optimalBB(1,2);
    rotationAngle = atand(xDist/yDist);

    %in hindsight this second transformation is not needed.
    
    %now rotate so optimal bounding box is axis-aligned
    R2 = R3D(rotationAngle, upVect);

    rotatedVertices = (R2 * rotatedVertices')';
    % Get bounding box corners
    minX = min(rotatedVertices(:,1));
    maxX = max(rotatedVertices(:,1));
    minY = min(rotatedVertices(:,2));
    maxY = max(rotatedVertices(:,2));
    z = (rotatedVertices(1,3));
    LL = [minX, minY,z];
    UL = [minX, maxY,z];
    UR = [maxX, maxY,z];
    LR = [maxX, minY,z];

    % Go back to original coordinates
    bbRestored = (R1' * (R2' * [LL;UL;UR;LR]'))';

    rotate = false;
    flipVert = false;
    flipHoriz = false;
    if abs(bbRestored(1,3) - bbRestored(2,3)) < abs(bbRestored(1,3) - bbRestored(4,3))
        rotate = true;
        fprintf('Rotating\n');
        temp = bbRestored(2,:);
        bbRestored(2,:) = bbRestored(4,:);
        bbRestored(4,:) = temp;
    end

    if bbRestored(1,3) > bbRestored(2,3)
        flipVert = true;
        fprintf('Flipping Vertical\n');
        temp = bbRestored(1,:);
        bbRestored(1,:) = bbRestored(2,:);
        bbRestored(2,:) = temp;
        temp = bbRestored(3,:);
        bbRestored(3,:) = bbRestored(4,:);
        bbRestored(4,:) = temp;
    end

    xVect = bbRestored(4,:) - bbRestored(1,:);
    yVect = bbRestored(2,:) - bbRestored(1,:);
    crossVect = cross(xVect, yVect);
    crossVect = crossVect / norm(crossVect);
    if (dot(crossVect, normal) ~= 1)
        flipHoriz = true;
        fprintf('Flipping Horizontal\n');
        temp = bbRestored(1,:);
        bbRestored(1,:) = bbRestored(4,:);
        bbRestored(4,:) = temp;
        temp = bbRestored(2,:);
        bbRestored(2,:) = bbRestored(3,:);
        bbRestored(3,:) = temp;
    end
    bbCorners = bbRestored;

    % Store the relative coords
    relCoords = zeros(size(rotatedVertices,1), 2);
    for i = 1:size(rotatedVertices,1)
        relX = (rotatedVertices(i,1) - minX)/(maxX - minX);
        relY = (rotatedVertices(i,2) - minY)/(maxY - minY);
        if rotate
            temp = relX;
            relX = relY;
            relY = temp;
        end
        if flipVert
            relY = 1 - relY;
        end
        if flipHoriz
            relX = 1 - relX;
        end
        if relX < 0.001
            relX = 0;
        end
        if relY < 0.001
            relY = 0;
        end
        if relX > 0.999
            relX = 1;
        end
        if relY > 0.999
            relY = 1;
        end
        relCoords(i,:) = [relX, relY];
    end
end

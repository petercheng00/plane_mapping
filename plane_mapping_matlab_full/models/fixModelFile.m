function fixModelFile()

%select input .model file
[inModelFile, inModelPath] = uigetfile('*.model', 'Select model file');
inModelFid = fopen(strcat(inModelPath, inModelFile));

%select output .model file location
[outModelName, outModelPath] = uiputfile(strcat(inModelPath, '*.model'), 'Save New Model File At');

%read in all planes
inModelData = fscanf(inModelFid, '%f', inf);
fclose(inModelFid);
numPlanes = inModelData(1,1);
pointer = 2;

outputPlanes = [];

%iterate over each plane
for i = 1:numPlanes
    plane.numVertices = inModelData(pointer,1);
    pointer = pointer + 1;
    plane.equation = inModelData(pointer:pointer+3, 1);
    pointer = pointer + 4;
  
    for j = 1:plane.numVertices
        plane.vertices(j,:) = [inModelData(pointer, 1),
                             inModelData(pointer + 1, 1),
                             inModelData(pointer + 2, 1)];
        pointer = pointer + 3;
    end

    %remove duplicate vertices
    if plane.numVertices <= 2
        continue;
    end
    i1 = plane.numVertices;
    i2 = 1;
    while i2 <= plane.numVertices
        if isequal(plane.vertices(i1,:), plane.vertices(i2,:))
            plane.vertices = [plane.vertices(1:i2-1,:); plane.vertices(i2+1:end,:)];
            plane.numVertices = plane.numVertices - 1;
            if i1 == plane.numVertices + 1
                i1 = plane.numVertices;
            end
        else
            i1 = i2;
            i2 = i2 + 1;
        end
    end

    %remove unnecessary vertices (in between two vertices)
    i1 = plane.numVertices - 1;
    i2 = plane.numVertices;
    i3 = 1;
    dir1 = i2 - i1;
    dir2 = i3 - i2;
    if isequal(dir2, dir1)
        plane.vertices = plane.vertices(1:end-1);
        plane.numVertices = plane.numVertices - 1;
    end
    i1 = plane.numVertices;
    i2 = 1;
    i3 = 2;
    while i3 <= plane.numVertices
        dir1 = plane.vertices(i2,:) - plane.vertices(i1,:);
        dir2 = plane.vertices(i3,:) - plane.vertices(i2,:);
        if isequal(dir2, dir1)
            plane.vertices = [plane.vertices(1:i2-1,:); plane.vertices(i2+1:end,:)];
            plane.numVertices = plane.numVertices - 1;
        else
            i1 = i2;
            i2 = i3;
            i3 = i3 + 1;
        end
    end
    
    %remove degenerate planes
    if plane.numVertices <= 2
        continue;
    end

    %fix vertex order
    %not implemented yet

    %fix normal vector
    side1 = plane.vertices(2,:) - plane.vertices(1,:);
    side2 = plane.vertices(3,:) - plane.vertices(2,:);
    normal = cross(side1, side2);
    normal = normal/norm(normal);
    if dot(normal, plane.equation(1:3)) < 0
        normal = -1 * normal;
    end
    plane_offset = -1 * dot(plane.vertices(1,:), normal);
    plane.equation = [normal, plane_offset];

    %save plane
    outputPlanes = [outputPlanes, plane];
end
%write to output file
outModelFid = fopen(strcat(outModelPath, outModelName), 'W');
fprintf(outModelFid, strcat(num2str(size(outputPlanes,2)), '\n'));
for i = 1:size(outputPlanes,2)
    plane = outputPlanes(i);
    fprintf(outModelFid, [num2str(plane.numVertices), '\n']);
    fprintf(outModelFid, [num2str(plane.equation(1)), ' ']);
    fprintf(outModelFid, [num2str(plane.equation(2)), ' ']);
    fprintf(outModelFid, [num2str(plane.equation(3)), ' ']);
    fprintf(outModelFid, [num2str(plane.equation(4)), '\n']);
    for j = 1:plane.numVertices
        vertex = plane.vertices(j,:);
        fprintf(outModelFid, [num2str(vertex(1)), ' ']);
        fprintf(outModelFid, [num2str(vertex(2)), ' ']);
        fprintf(outModelFid, [num2str(vertex(3)), '\n']);
    end
end
        
fclose(outModelFid);

end
function dividePlanes()


%minimum score required to add a triangle
scoreThreshold = 0.1;
    
%minimum score loss allowed when adding a triangle
diffThreshold = 0.2712;

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
	
	%rotate plane so we can deal with it in 2D
    upVect = [0, 0, 1];
    normal = plane.equation(1:3);
    if normal(1) == 0 && normal(2) == 0 && (normal(3) == 1 || normal(3) == -1)
        % plane is already flat, so R1 is just identity.
        R1 = eye(3);
    else
        rotationAxis = cross(normal, upVect);
        rotationAngle = acosd(dot(normal, upVect)/norm(normal)/norm(upVect));

        %first rotate to make plane flat
        R1 = R3D(rotationAngle, rotationAxis);
        plane.vertices = (R1 * plane.vertices')';
    end
    %ensure points go in clockwise order
    if ~isClockwise(plane.vertices(:,1:2))
        plane.vertices = flipud(plane.vertices);
    end
	outputPlanes = divide2DPlane(plane, scoreThreshold, diffThreshold);
	
	%rotate planes back into 3D space
	for j = 1:size(outputPlanes)
		outputPlanes(j).vertices = (R1' * outputPlanes(j).vertices')';
	end
	
end

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

for i=1:size(outputPlanes,2);
    vert = [outputPlanes(i).vertices(:,1),outputPlanes(i).vertices(:,2),outputPlanes(i).vertices(:,3)];
    fac=1:size(outputPlanes(i).vertices,1);
    patch('vertices', vert,'faces',fac,'facecolor',rand(1,3));
    view(3); 
    daspect([1 1 1]);
    axis('tight');
end

end

function c = isClockwise(v)
    slopeSum = (v(1,1) - v(end,1)) * (v(1,2) + v(end,2));
    for j = 2:size(v,1)
        slopeSum = slopeSum + ((v(j,1) - v(j-1,1))*(v(j,2) + v(j-1,2)));
    end
    c = slopeSum >= 0;
end
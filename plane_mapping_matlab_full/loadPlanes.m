function loadedPlanes = loadPlanes()

  % This function basically reads the input files
  % that specify which images are used for this plane
  % and what the corner points are in 3D space. Then it
  % calls texturePlane() to do the actual texture mapping
  
  global modelName
  global imgPath
  global inputPath
  global modelPath
  global outputPath
  global mapFile
  global prePath
  global textureStyle
  global uncroppedChosen
  global uncroppedUnchosen
  global fillHoles
  
  addpath(inputPath);
  close all

  % Load in all the camera position and image data for plane 'plane_num'
  % Note: your plane numbers start at zero but matlab starts at 1.
  disp(['importing data...'])
  filenames = importdata('filenames.txt');
  masks = importdata('masks.txt');
  t_cam2world = importdata('translations.txt'); 
  R_cam2world = importdata('rotations.txt'); % Dont forget quat2rot
  imgplanes = importdata('imgplanes.txt');
  
  % Camera Intrinics - from atlasImages.txt
  K = [ 612 0 1224 ; ...
        0 612 1024 ; ...
        0 0 1 ];
  
  % Process the corners of the planes
  model = dlmread(modelPath, ' ');
  nplanes = model(1);
  linenum = 2;
  
  
  prevLoaded = 0;
  loadedPlanes = [];
  for pnum=1:nplanes
    disp(['loading plane', num2str(pnum)])
    newPlane = plane();
    
    % Create a folder to store the resulting plane
    folder = strcat(outputPath, '/textures', num2str(pnum));
    warning off
    mkdir(folder);
    warning on
      
    my_filenames = filenames(imgplanes==(pnum-1));
    my_masks = masks(imgplanes==(pnum-1));
    my_t_cam2world = t_cam2world(imgplanes==(pnum-1),:);
    my_R_cam2world = R_cam2world(imgplanes==(pnum-1),:);
    for i=1:size(my_R_cam2world,1)
      rotations{i} = quat2rot(my_R_cam2world(i,:));
    end
    
	numcorners = model(linenum,1);
    normal = model(linenum+1,1:3);
    normal = normal/norm(normal);
    plane_offset = model(linenum+1,4);
    vertices = model(linenum+2:linenum+numcorners+1,1:3);
    
    [bbCorners,relCoords] = calculate_bounding_box(vertices,normal);
    
    %planes{pnum}.normal = normal;
    %planes{pnum}.vertices = vertices;
    %planes{pnum}.plane_offset = plane_offset;
    %if pnum == plane_num
	%	calculate_bounding_box;
    %end
    
    planeCorners = bbCorners' .* 1000;
    
    % Visualize the plane in 3D space
    center = [mean(vertices(:,1)), mean(vertices(:,2)), mean(vertices(:,3))];
    normalEnd = [center(1,1) + 10*normal(1), center(1,2) + 10*normal(2), center(1,3) + 10*normal(3) ];
    plot3(0,0,0,'kx')
    patch(bbCorners(:,1),bbCorners(:,2),bbCorners(:,3),'c');
    hold on;
    patch(vertices(:,1)+0.1*normal(1),vertices(:,2)+0.1*normal(2),vertices(:,3)+0.1*normal(3),'k');
    line([center(1), normalEnd(1)], [center(2), normalEnd(2)], [center(3), normalEnd(3)], 'linewidth', 5)
    axis('equal')
    hold off;
    drawnow
    
    
    % We want plane corners arranged like this
    % 2   3 
    % 1   4
    % Normal should be pointing out the screen at you
    
    
    
    %newPlane.base = planeCorners(:,3);
    %newPlane.down = planeCorners(:,4)-newPlane.base;
    %newPlane.side = planeCorners(:,2)-newPlane.base;
    newPlane.vertices = vertices' .* 1000 ;
    newPlane.bbCorners = planeCorners;
    newPlane.base = planeCorners(:,2);
    newPlane.down = planeCorners(:,1) - newPlane.base;
    newPlane.side = planeCorners(:,3) - newPlane.base;
    newPlane.normal = normal';
    newPlane.d = plane_offset * 1000;
    
    % should have 4 corners after using bbcorners
    if(size(planeCorners,2)~=4)
        fprintf('plane does not have four corners\n');
        keyboard
    end
    % Ratio is the number of pixels per centemeter or something. I'm not entirely sure. Just make
    % it larger if you want higher-resolution planes
    newPlane.ratio = 0.10;
    % Width and height of the plane in pixels
    newPlane.width = round(newPlane.ratio*norm(newPlane.side));
    newPlane.height = round(newPlane.ratio*norm(newPlane.down));
    newPlane.maxshift = round(newPlane.ratio * 400); % 400 mm shift
    newPlane.blendpx = round(newPlane.ratio * 400); % 400cm blending
    newPlane.image_filenames = my_filenames;
    newPlane.image_masks = my_masks;
    newPlane.image_rotations = rotations;
    newPlane.t_cam2world = my_t_cam2world;
    newPlane.K = K;
    
    
    
    %write to mapFile
    fid = fopen(mapFile, 'a');
    fprintf(fid, [num2str(size(vertices,1)), '\n']);
    fprintf(fid, [prePath, '/', folder, '/', textureStyle, '.jpg\n']);
    for vertInd = 1:size(relCoords,1)
      fprintf(fid, [num2str(relCoords(vertInd,1),4), ' ', num2str(relCoords(vertInd,2),4), '\n']);
    end
    fclose(fid);
    
    

    
	pnum = pnum + 1; 
    linenum = linenum + numcorners + 2;
    loadedPlanes = [loadedPlanes newPlane];
  end
end


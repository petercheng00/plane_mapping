function loadPlane(plane_num)

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
  filenames = importdata('filenames.txt');
  masks = importdata('masks.txt');
  t_cam2world = importdata('translations.txt'); 
  R_cam2world = importdata('rotations.txt'); % Dont forget quat2rot
  imgplanes = importdata('imgplanes.txt');
  filenames = filenames(imgplanes==(plane_num-1));
  masks = masks(imgplanes==(plane_num-1));
  t_cam2world = t_cam2world(imgplanes==(plane_num-1),:);
  R_cam2world = R_cam2world(imgplanes==(plane_num-1),:);
  for i=1:size(R_cam2world,1)
    rotations{i} = quat2rot(R_cam2world(i,:));
  end
  % Camera Intrinics - from atlasImages.txt
  K = [ 612 0 1224 ; ...
        0 612 1024 ; ...
        0 0 1 ];
  
  % Process the corners of the planes
  model = dlmread(modelPath, ' ');
  nplanes = model(1);
  linenum = 2;
  
  
  for pnum=1:nplanes
	numcorners = model(linenum,1);
    normal = model(linenum+1,1:3);
    normal = normal/norm(normal);
    plane_offset = model(linenum+1,4);
    vertices = model(linenum+2:linenum+numcorners+1,1:3);
    planes{pnum}.normal = normal;
    planes{pnum}.vertices = vertices;
    planes{pnum}.plane_offset = plane_offset;
    if pnum == plane_num
		calculate_bounding_box;
	end
	pnum = pnum + 1; 
    linenum = linenum + numcorners + 2;
  end
  % Visualize the plane in 3D space
  vertices = planes{plane_num}.vertices;
  bbcorners = planes{plane_num}.bbcorners;
  center = [mean(vertices(:,1)), mean(vertices(:,2)), mean(vertices(:,3))];
  normal = planes{plane_num}.normal;
  normalEnd = [center(1,1) + 10*normal(1), center(1,2) + 10*normal(2), center(1,3) + 10*normal(3) ];
  figure
  plot3(0,0,0,'kx')
  patch(bbcorners(:,1),bbcorners(:,2),bbcorners(:,3),'c');
  hold on;
  patch(vertices(:,1)+0.1*normal(1),vertices(:,2)+0.1*normal(2),vertices(:,3)+0.1*normal(3),'k');
  line([center(1), normalEnd(1)], [center(2), normalEnd(2)], [center(3), normalEnd(3)], 'linewidth', 5)
  axis('equal')
  hold off;
  drawnow
  % Find the plane corners for plane plane_num
  planeCorners_world = planes{plane_num}.bbcorners' .* 1000;
  % We want plane corners arranged like this
  % 2   3 
  % 1   4
  % Normal should be pointing out the screen at you
  
  % Thus (
  
  % Create a folder to store the resulting plane
  folder = strcat(outputPath, '/textures', num2str(plane_num));
  warning off
  mkdir(folder);
  warning on
  % Generate plane and save it to the folder
  
  %write to mapFile
  fid = fopen(mapFile, 'a');
  fprintf(fid, [num2str(size(planes{plane_num}.vertices,1)), '\n']);
  fprintf(fid, [prePath, '/', folder, '/', textureStyle, '.jpg\n']);
  for vertInd = 1:size(planes{plane_num}.relCoords,1)
      fprintf(fid, [num2str(planes{plane_num}.relCoords(vertInd,1),4), ' ', num2str(planes{plane_num}.relCoords(vertInd,2),4), '\n']);
  end
  fclose(fid);
  
  fprintf('Beginning Texture\n');
  texturePlane(filenames, masks, rotations, t_cam2world, planeCorners_world, K, folder, planes{plane_num}.normal,...
      planes{plane_num}.plane_offset, planes([1:plane_num-1 plane_num+1:end]))

end


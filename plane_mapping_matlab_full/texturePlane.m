function texturePlane(planes,pnum)

  global modelName
  global imgPath
  global inputPath
  global modelPath
  global outputPath
  global mapFile
  global prePath
  global textureStyle
  global fillHoles


addpath('sift');
addpath('ransac');

p = planes(pnum);
p = p.set_tiles();
p = p.filter_useless();

% not really useful anymore
p = p.sort_images2();
% if we do the following occlusion check, downside is that we may
% prematurely crop areas that won't be cropped after shifting.
% upside is that we make sure not to search for sift features in the bad areas
% for now not doing just to save time, haven't really tested
% checkOcclusion(planes, planeNum);

p = p.set_sift();
p = p.fix_locations();
checkOcclusion(planes,pnum);
p = p.filter_useless();
if (strcmp(textureStyle, 'naive'))
    p = p.print_images();
elseif (strcmp(textureStyle,'greedy_area'))
    p = p.print_greedy_area();
elseif (strcmp(textureStyle,'greedy_cost'))
    p = p.print_greedy_cost();
elseif (strcmp(textureStyle, 'dynprog'))
    images = p.repeated_shortest_path();
    % images always go in order of best to worst
    %p = p.painters_algorithm(images);
    %p = p.minimum_blending(images);
    
    %this method is best because it doesn't worry about cropping
    %however, shortest path uses cropping, so should use another image
    %selection method
    
    p = p.minimum_blending(images);
    p = p.minimum_blending(1:size(p.images,2));
    %p = p.native_blending(images);
end

% this is necessary when we throw out images from Stewart that we don't
% want. This should be re-written to be more general though
if fillHoles
    p = p.fill_holes();
end

imshow(uint8(p.outimg))
drawnow
% Print final image
folder = strcat(outputPath, '/textures', num2str(pnum));
warning off
mkdir(folder);
warning on
cd(folder);
imwrite(uint8(p.outimg), [textureStyle, '.jpg']);
cd ('../../../..')
end



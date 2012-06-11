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

% not sure why, but images with diagonal sections get antialiased, which
% messes up our blending. We need to remove these antialiased pixels
p = p.remove_border_pixels();


% not really useful anymore
%p = p.sort_images2();
% if we do the following occlusion check, downside is that we may
% prematurely crop areas that won't be cropped after shifting.
% upside is that we make sure not to search for sift features in the bad areas
% for now not doing just to save time, haven't really tested
% checkOcclusion(planes, planeNum);

% we don't want sift to pick up unused parts of our rectangular images as
% features, so give it cropped, filled rectangles to work on.
p = p.set_sift();
p = p.fix_locations();
p = p.filter_useless();
disp('occlusion checking...')
checkOcclusion(planes,pnum);
p = p.filter_useless();
if (strcmp(textureStyle, 'naive'))
    p = p.print_images();
elseif (strcmp(textureStyle,'greedy_area'))
    p = p.print_greedy_area();
elseif (strcmp(textureStyle,'greedy_cost'))
    p = p.print_greedy_cost();
elseif (strcmp(textureStyle, 'dynprog'))
    disp('dynprog image selection...')
    images = p.repeated_shortest_path();
    % images always go in order of best to worst
    %p = p.painters_algorithm(images);
    keyboard
    
    disp('doing minimum blending')
    p = p.minimum_blending(images);
    keyboard
    p = p.minimum_blending(1:size(p.images,2));
    %disp('texturing with native blending...')
    %p = p.native_blending(images);
end

% this is necessary when we throw out images from Stewart that we don't
% want. This should be re-written to be more general though
if fillHoles
    disp('Doing texture extrapolation to fill holes...')
    p = p.fill_holes();
end
disp('Writing Image...')
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
disp('Done!')
end



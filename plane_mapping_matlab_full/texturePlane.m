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
if (p.normal(3) == 1 || p.normal(3) == -1)
    p = p.set_tiles_no_rotate();
else
    p = p.set_tiles_and_rotate();
end
%p = p.set_tiles_and_rotate();
p = p.filter_useless();
if size(p.images,2) == 0
    return
end
p = p.sort_images();
disp(['tiles set, num planes = ', num2str(size(p.images,2))]);
% not sure why, but images with diagonal sections get antialiased, which
% messes up our blending. We need to remove these antialiased pixels
p = p.remove_border_pixels();
%--------------------------------
% not really useful anymore
%p = p.sort_images2();
% if we do the following occlusion check, downside is that we may
% prematurely crop areas that won't be cropped after shifting.
% upside is that we make sure not to search for sift features in the bad areas
% for now not doing just to save time, haven't really tested
% checkOcclusion(planes, planeNum);
%---------------------------------
% we don't want sift to pick up unused parts of our rectangular images as
% features, so give it cropped, filled rectangles to work on.
p = p.set_sift();
p = p.fix_locations();
p = p.filter_useless();
disp(['sift adjustment done, num planes = ', num2str(size(p.images,2))]);
checkOcclusion(planes,pnum);
p = p.filter_useless();
disp(['occlusion checks complete, num planes = ', num2str(size(p.images,2))]);
%disp('averaging image intensities');
%p = p.fix_intensities();

myTextureStyle = textureStyle;
if (strcmp(textureStyle, 'dynprogsplit_plane'))
    if (p.normal(3) == 1 || p.normal(3) == -1)
        myTextureStyle = 'split_plane';
    else
        myTextureStyle = 'dynprog';
    end
end

if (strcmp(myTextureStyle, 'naive'))
    p = p.print_images();
elseif (strcmp(myTextureStyle,'greedy_area'))
    p = p.print_greedy_area();
elseif (strcmp(myTextureStyle,'greedy_cost'))
    p = p.print_greedy_cost();
elseif (strcmp(myTextureStyle, 'dynprog'))
    disp('dynprog image selection...')
    images = sort(p.repeated_shortest_path());
    %images = p.greedy_overlap_camera_cost();
    keyboard
    disp('doing minimum blending')
    p = p.minimum_blending(images);
    p = p.minimum_blending(1:size(p.images,2));
elseif (strcmp(myTextureStyle, 'split_plane'))
    disp('texturing using split_plane method (stewarts)')
    step = 5;
    blend = max(10,round(step/10));
    maxCacheAngle = 180;
    maxAngle = 180;
    p = p.split_plane_texturing(step, blend, maxCacheAngle, maxAngle);
elseif (strcmp(myTextureStyle, 'painter'))
    disp('texturing with painters algorithm')
    images = p.repeated_shortest_path();
    p = p.painters_algorithm(images);
elseif (strcmp(myTextureStyle, 'native'))
    disp('texturing with native blending...')
    images = p.repeated_shortest_path();
    p = p.native_blending(images);
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
imwrite(uint8(p.outimg), [myTextureStyle, '.jpg']);
cd ('../../../..')
disp('Done!')
end



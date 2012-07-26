function texturePlane(planes,pnum, outputPath, textureStyle, fillHoles, usePreProcessed)


addpath('sift');
addpath('ransac');


p = planes(pnum);

myTextureStyle = textureStyle;
if (strcmp(textureStyle, 'dynprogsplit_plane'))
    if (p.normal(3) == 1 || p.normal(3) == -1)
        myTextureStyle = 'split_plane';
    else
        myTextureStyle = 'dynprog';
        return
    end
end


p.outimg = zeros(p.height, p.width, 3);

preProcessedFile = strcat(outputPath, '/textures', num2str(pnum), '/preProcessed.mat');
if ~usePreProcessed || ~exist(preProcessedFile, 'file')
    
    p = p.load_images();
    
    if (p.normal(3) == 1 || p.normal(3) == -1)
        p = p.set_tiles_no_rotate();
    else
        p = p.set_tiles_and_rotate();
    end
    
    
    p = p.filter_useless();
    if size(p.images,2) == 0
        return
    end
    p = p.sort_images();
    disp(['plane ', num2str(pnum), ': tiles set, num images = ', num2str(size(p.images,2))]);
    
    % not sure why, but images with diagonal sections get antialiased, which
    % messes up our blending. We need to remove these antialiased pixels
    p = p.remove_border_pixels();

    p = p.set_sift();
    p = p.fix_locations();
    p = p.filter_useless();
    disp(['plane ', num2str(pnum), ': sift adjustment done, num images = ', num2str(size(p.images,2))]);
    checkOcclusion(planes,pnum);
    p = p.filter_useless();
    disp(['plane ', num2str(pnum), ': occlusion checks complete, num images = ', num2str(size(p.images,2))]);
    
    %disp('averaging image intensities');
    %p = p.fix_intensities();

    %save results of all this preprocessing
    for i = 1:size(p.images,2)
        p.images(i).img = 0;
        p.images(i).mask = 0;
        p.images(i).mytile = 0;
    end
    saveHelper(p.images, preProcessedFile);
else
    disp(['plane ', num2str(pnum), ': using preprocessed images']);
    preProcessed = load(preProcessedFile);
    p.images = preProcessed.preProcessedImages;
end

if (strcmp(myTextureStyle, 'naive'))
    p = p.print_images();
elseif (strcmp(myTextureStyle,'greedy_area'))
    p = p.print_greedy_area();
elseif (strcmp(myTextureStyle,'greedy_cost'))
    p = p.print_greedy_cost();
elseif (strcmp(myTextureStyle, 'dynprog'))
    disp(['plane ', num2str(pnum), ': dynprog image selection...'])
    images = sort(p.repeated_shortest_path());
    %images = p.greedy_overlap_camera_cost();
    disp(['plane ', num2str(pnum), ': doing minimum blending'])
    p = p.minimum_blending(images);
    p = p.minimum_blending(1:size(p.images,2));
elseif (strcmp(myTextureStyle, 'split_plane'))
    disp(['plane ', num2str(pnum), ': texturing using split_plane method (stewarts)'])
    step = 5;
    blend = max(10,round(step/10));
    maxCacheAngle = 45;
    maxAngle = 180;
    p = p.split_plane_texturing(step, blend, maxCacheAngle, maxAngle);
elseif (strcmp(myTextureStyle, 'painter'))
    disp(['plane ', num2str(pnum), ': texturing with painters algorithm'])
    images = p.repeated_shortest_path();
    p = p.painters_algorithm(images);
elseif (strcmp(myTextureStyle, 'native'))
    disp(['plane ', num2str(pnum), ': texturing with native blending...'])
    images = p.repeated_shortest_path();
    p = p.native_blending(images);
end

% this is necessary when we throw out images from Stewart that we don't
% want. This should be re-written to be more general though
if fillHoles
    disp(['plane ', num2str(pnum), ': Doing texture extrapolation to fill holes...'])
    p = p.fill_holes();
end
disp(['plane ', num2str(pnum), ': Writing Image...'])
%imshow(uint8(p.outimg))
%drawnow
% Print final image
folder = strcat(outputPath, '/textures', num2str(pnum));
warning off
mkdir(folder);
warning on
cd(folder);
imwrite(uint8(p.outimg), [myTextureStyle, '.jpg']);
cd ('../../../..')
disp(['plane ', num2str(pnum), ': Done!'])
p.images = [];
end


function saveHelper(var, location)
    disp(['saving at ', location]);
    preProcessedImages = var;
    save('-v7.3', location, 'preProcessedImages');
end


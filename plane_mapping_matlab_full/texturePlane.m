function texturePlane(p,pnum)

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

%p = plane();
%p.base = corners(:,3);
%p.down = corners(:,4)-p.base;
%p.side = corners(:,2)-p.base;
%p.normal = normal';
%p.d = offset;

% I'm not handling the case when the plane has more than 4 corners
%four_corners = (size(corners,2) == 4);
%if(~four_corners)
%    fprintf('plane does not have four corners\n');
%    return
%end
% Ratio is the number of pixels per centemeter or something. I'm not entirely sure. Just make
% it larger if you want higher-resolution planes
%p.ratio = 0.10;
% Width and height of the plane in pixels
%p.width = round(p.ratio*norm(p.side));
%p.height = round(p.ratio*norm(p.down));
%p.maxshift = round(p.ratio * 400); % 400 mm shift
%p.blendpx = round(p.ratio * 400); % 400cm blending
%p = p.load_images(filenames, masks, rotations, t_cam2world, K);
%p = p.sort_images();
%p.outimg = zeros(p.height, p.width, 3);

p = p.set_tiles();
p = p.set_tiles_on_plane();
p = p.filter_useless();
p = p.sort_images2();

p = p.set_sift();
p = p.fix_locations();
p = p.set_tiles_on_plane();
if (strcmp(textureStyle, 'naive'))
    p = p.print_images();
elseif (strcmp(textureStyle,'greedy_area'))
    p = p.print_greedy_area();
elseif (strcmp(textureStyle,'greedy_cost'))
    p = p.print_greedy_cost();
elseif (strcmp(textureStyle, 'dynprog'))
    p = p.setup_DAG();
    p = p.set_overlap(size(p.images,2));
    p = p.print_dynprog();
end

% this is necessary when we throw out images from Stewart that we don't
% want. This should be re-written to be more general though
if fillHoles
    p = p.fill_holes();
end
imshow(uint8(p.outimg));
p.outimg(:,:,1) = fliplr(p.outimg(:,:,1));
p.outimg(:,:,2) = fliplr(p.outimg(:,:,2));
p.outimg(:,:,3) = fliplr(p.outimg(:,:,3));
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



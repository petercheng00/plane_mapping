function texturePlane(filenames, masks, rotations, t_cam2world, corners, K, folder, ...
    normal, offset, otherPlanes)

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

% This is the top corner of the plane
p = plane();
p.base = corners(:,3);
p.down = corners(:,4)-p.base;
p.side = corners(:,2)-p.base;
p.normal = normal';
p.d = offset;

% I'm not handling the case when the plane has more than 4 corners
four_corners = (size(corners,2) == 4);
if(~four_corners)
    fprintf('plane does not have four corners\n');
    return
end
% Ratio is the number of pixels per centemeter or something. I'm not entirely sure. Just make
% it larger if you want higher-resolution planes
p.ratio = 0.10;
% Width and height of the plane in pixels
p.width = round(p.ratio*norm(p.side));
p.height = round(p.ratio*norm(p.down));
p.maxshift = round(p.ratio * 400); % 400 mm shift
p.blendpx = round(p.ratio * 400); % 400cm blending
p = p.load_images(filenames, masks, rotations, t_cam2world, K);
p = p.sort_images();
p.outimg = zeros(p.height, p.width, 3);
p = p.set_tiles();
p = p.set_tiles_on_plane();
p = p.filter_useless();
p = p.sort_images2();

%visualize plane and each camera

%center = [mean(corners(:,1)), mean(corners(:,2)), mean(corners(:,3))];
%normalEnd = [center(1,1) + 10*normal(1), center(1,2) + 10*normal(2), center(1,3) + 10*normal(3) ];
%figure
%plot3(0,0,0,'kx')
%patch(corners(:,1),corners(:,2),corners(:,3),'c');
%hold on;
%line([center(1), normalEnd(1)], [center(2), normalEnd(2)], [center(3), normalEnd(3)], 'linewidth', 5)
%axis('equal')
%hold off;
%drawnow
%keyboard

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
    keyboard
    p = p.fill_holes();
    keyboard
end
p.outimg(:,:,1) = fliplr(p.outimg(:,:,1));
p.outimg(:,:,2) = fliplr(p.outimg(:,:,2));
p.outimg(:,:,3) = fliplr(p.outimg(:,:,3));
imshow(uint8(p.outimg))
drawnow
% Print final image
cd(folder);
imwrite(uint8(p.outimg), [textureStyle, '.jpg']);
cd ('../../../..')
end



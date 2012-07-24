   classdef plane_img < matlab.mixin.Copyable
   % write a description of the class here.
       properties
       % define the properties of the class here, (like fields of a struct)
           img;
           mask;
           r;
           t;
           K;
           cam_dist;
           cam_angle;
           mytile;
           mytile_on_plane;
		   overlap = [];
           useful = true;
       end
       methods
           % There is an implicit constructor
           
           function does_contain_box = contains_box(obj, box, p)
               does_contain_box = true;
               
               %Project the four corners of box to the plane
               plane_pts = [[box.row_min ; box.col_min] ...
                        [box.row_min ; box.col_max] ...
                        [box.row_max ; box.col_min] ...
                        [box.row_max ; box.col_max]];
               world_pts = p.get_world_pts(plane_pts);
               im_pts = obj.get_image_pts(world_pts);
               contains_points = obj.does_contain_point(im_pts);
               if(~prod(contains_points))
                   does_contain_box = false;
               end
           end
           
           function camera_pts = get_camera_pts(obj, world_pts)
               npoints = size(world_pts,2);
               camera_pts = obj.r'*(world_pts - repmat(obj.t, [1, npoints]));
               camera_pts = obj.K*camera_pts;
               %im_pts(1,:) = round(im_pts(1,:) ./ im_pts(3,:));
               %im_pts(2,:) = round(im_pts(2,:) ./ im_pts(3,:));
               %im_pts = im_pts(1:2,:);
               
               %curImgRotationInv = obj.r';
               %curImgTranslationInv = (-(curImgRotationInv*obj.t));
               %camera_pts = repmat(curImgRotationInv,[1,npoints])*plane_pts + ...
               %    repmat(curImgTranslationInv,[1,npoints]);
               %camera_pts = obj.K * camera_pts;
           end
           
           function im_pts = get_image_pts(obj, camera_pts)
               im_pts(1,:) = round(camera_pts(1,:) ./ camera_pts(3,:));
               im_pts(2,:) = round(camera_pts(2,:) ./ camera_pts(3,:));
           end
           
           function does_contain_point = contains_point(obj,camera_pts)
               im_pts = obj.get_image_pts(camera_pts);
               %does_contain_point(1:size(im_pts,2)) = true;
               % don't allow point to be behind the camera
               does_contain_point = logical(camera_pts(3,:) > 0.001);
               [h w c] = size(obj.img);
               does_contain_point = does_contain_point .* (im_pts(1,:) >= 1);
               does_contain_point = does_contain_point .* (im_pts(1,:) <= w);
               does_contain_point = does_contain_point .* (im_pts(2,:) >= 1);
               does_contain_point = does_contain_point .* (im_pts(2,:) <= h);
               im_pts_linear = obj.linearize_pts(im_pts);
               isinmask = obj.mask(im_pts_linear(logical(does_contain_point)));
               does_contain_point(logical(does_contain_point)) = isinmask;
               does_contain_point = logical(does_contain_point);

           end
           
           function im_pts_linear = linearize_pts(obj, im_pts)
               [h w c] = size(obj.img);
               im_pts_linear = uint32(im_pts(2,:) +  h*(im_pts(1,:)-1));
           end
           
           function obj = set_tile_naive(obj, p)
               box = p.get_camera_box(obj.t, 5000);
               obj = obj.set_tile(box, p);
               obj.mytile = obj.mytile.crop();
               obj = obj.set_tile_on_plane(p);
           end
           
           function obj = set_tile_and_rotate(obj, p)
               box = p.get_camera_box(obj.t, 10000);
               obj = obj.set_tile(box, p);
               if (sum(sum(obj.mytile.orig_valid)) > 0)
                   obj.useful = true;
                   obj = obj.set_tile_on_plane(p);
                   obj.mytile_on_plane = obj.mytile_on_plane.crop();
                   if (numel(obj.mytile_on_plane.cropped_valid) > 0)
                       angle = rectify_image(uint8(obj.mytile_on_plane.cropped_data));
                       %obj.mytile = obj.mytile.rotate(angle);
                       %obj = obj.set_tile_on_plane(p);
                       %obj.mytile_on_plane = obj.mytile_on_plane.crop();
                       obj.mytile_on_plane = obj.mytile_on_plane.rotate(angle);
                       obj.mytile_on_plane = obj.mytile_on_plane.crop();
                       obj.useful = (numel(obj.mytile_on_plane.cropped_valid) > 0);

                   else
                       obj.useful = false;
                   end
               else
                   obj.useful = false;
               end
           end
           
           function obj = set_tile_no_rotate(obj, p)
               box = p.get_camera_box(obj.t, 10000);
               obj = obj.set_tile(box, p);
               if (sum(sum(obj.mytile.orig_valid)) > 0)
                   obj.useful = true;
                   %obj.mytile = obj.mytile.crop();
                   obj = obj.set_tile_on_plane(p);
                   obj.mytile_on_plane = obj.mytile_on_plane.crop();
                   obj.useful = (numel(obj.mytile_on_plane.cropped_valid) > 0);
               else
                   obj.useful = false;
               end
           end
      
           function obj = set_tile(obj, box, p)
               obj.mytile = tile();
               obj.mytile.orig_box = box;
               [~,~, c] = size(obj.img);
               plane_pts = p.get_plane_pts(box);
               world_pts = p.get_world_pts(plane_pts);
               camera_pts = obj.get_camera_pts(world_pts);
               obj.mytile.orig_valid = logical(obj.contains_point(camera_pts));
               im_pts = obj.get_image_pts(camera_pts);
               im_pts_linear = obj.linearize_pts(im_pts);
               im_pts_linear = im_pts_linear(obj.mytile.orig_valid);
               obj.mytile.orig_data = zeros(box.row_max-box.row_min+1,...
                                       box.col_max-box.col_min+1,...
                                       c);
               obj.mytile.orig_valid = reshape(obj.mytile.orig_valid, ...
                                 size(obj.mytile.orig_data(:,:,1)));
               for chan = 1:c
                   tmp_img = obj.img(:,:,chan);
                   tmp_tile = obj.mytile.orig_data(:,:,chan);
                   tmp_tile(obj.mytile.orig_valid) = tmp_img(im_pts_linear);
                   obj.mytile.orig_data(:,:,chan) = tmp_tile;
               end
               
               
               plane_center_world = p.get_world_pts([(box.row_max+box.row_min)/2;(box.col_max+box.col_min)/2]);
               obj.cam_dist = norm(obj.t - plane_center_world);
               rotNorm = -1 * (obj.r * [0;0;1]);
               obj.cam_angle = acos(dot(rotNorm,p.normal)/(norm(rotNorm)*norm(p.normal)));
               obj.cam_angle = (180/pi) * obj.cam_angle;
           end

           function obj = set_tile_on_plane(obj, p)
               obj.mytile_on_plane = obj.mytile.get_tile_on_plane(p);
               b = obj.mytile_on_plane.orig_box;
               if(b.row_max-b.row_min < 1 || b.col_max-b.col_min < 1)
                   obj.useful = false;
                   return
               end
               % don't think this is needed anymore
               %obj.mytile_on_plane = ...
               %    obj.mytile_on_plane.set_border_mask(p.blendpx);
           end
           
           function obj = doImageGain(obj, gain)
               keyboard
               obj.mytile_on_plane.orig_data = obj.mytile_on_plane.orig_data * gain;
               obj.mytile_on_plane.cropped_data = obj.mytile_on_plane.cropped_data * gain;
               keyboard
           end
           
           function contribution = get_contribution(obj, grid)
               % My grid is 1 where it is filled
               % Their grid is 1 where it is filled
               grid_compliment = (1-grid);
               box = obj.mytile_on_plane.box;
               grid_compliment = grid_compliment(box.row_min:box.row_max,...
                                                 box.col_min:box.col_max);
               contribution = sum(sum(grid_compliment .* ...
                                      obj.mytile_on_plane.isvalid));                              
           end
           
           function contribution = get_uncroppedContribution(obj, grid)
               % My grid is 1 where it is filled
               % Their grid is 1 where it is filled
               grid_compliment = (1-grid);
               box = obj.mytile_on_plane.origbox;
               grid_compliment = grid_compliment(box.row_min:box.row_max,...
                                                 box.col_min:box.col_max);
               filledArea = obj.mytile_on_plane.origdata(:,:,1) | ...
                            obj.mytile_on_plane.origdata(:,:,2) | ...
                            obj.mytile_on_plane.origdata(:,:,3);
               grid_compliment = grid_compliment .* filledArea;
               contribution = sum(sum(grid_compliment .* ...
                                      obj.mytile_on_plane.origisvalid));                              
           end
           
           function grid = update_logical(obj, grid)
               temp = grid * 0;
               temp(obj.mytile_on_plane.orig_box.row_min:obj.mytile_on_plane.orig_box.row_max, ...
                    obj.mytile_on_plane.orig_box.col_min:obj.mytile_on_plane.orig_box.col_max) = ...
                    (sum(obj.mytile_on_plane.orig_data,3) ~= 0);
               grid = grid | temp;
           end
           
           function grid = update_uncropped_logical(obj, grid)
               % My grid is 1 where it is filled
               % Their grid is 1 where it is filled
               box = obj.mytile_on_plane.origbox;
               grid(box.row_min:box.row_max,box.col_min:box.col_max) = true;                            
           end
           
           function obj = set_sift(obj)
               if(obj.useful)
                   obj.mytile_on_plane = obj.mytile_on_plane.set_sift();
               end
           end
           

       end
   end

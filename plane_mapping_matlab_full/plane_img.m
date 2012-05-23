   classdef plane_img < matlab.mixin.Copyable
   % write a description of the class here.
       properties
       % define the properties of the class here, (like fields of a struct)
           img;
           mask;
           r;
           t;
           K;
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
           
           function im_pts = get_image_pts(obj, plane_pts)
               npoints = size(plane_pts,2);
               camera_pts = obj.r'*(plane_pts - repmat(obj.t, [1, npoints]));
               im_pts = obj.K*camera_pts;
               im_pts(1,:) = round(im_pts(1,:) ./ im_pts(3,:));
               im_pts(2,:) = round(im_pts(2,:) ./ im_pts(3,:));
               im_pts = im_pts(1:2,:);
           end
           
           function does_contain_point = contains_point(obj,im_pts)
               does_contain_point(1:size(im_pts,2)) = true;
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
               box = p.get_camera_box(obj.t, 5000);
               uncroppedbox = p.get_camera_box(obj.t, 5000);
               obj = obj.set_tile(box, uncroppedbox, p);
               obj.mytile = obj.mytile.crop();
               obj = obj.set_tile_on_plane(p);
               if(obj.useful)
                   angle = rectify_image(uint8(obj.mytile_on_plane.data));
                   obj.mytile = obj.mytile.rotate(angle);
                   obj.mytile = obj.mytile.crop();
               end
           end
      
           function obj = set_tile(obj, box, uncroppedbox, p)
               obj.mytile = tile();
               obj.mytile.box = box;
               obj.mytile.origbox = uncroppedbox;
               [h w c] = size(obj.img);
               plane_pts = p.get_plane_pts(box);
               world_pts = p.get_world_pts(plane_pts);
               im_pts = obj.get_image_pts(world_pts);
               obj.mytile.isvalid = logical(obj.contains_point(im_pts));
               im_pts_linear = obj.linearize_pts(im_pts);
               im_pts_linear = im_pts_linear(obj.mytile.isvalid);
               obj.mytile.data = zeros(box.row_max-box.row_min+1,...
                                       box.col_max-box.col_min+1,...
                                       c);
               obj.mytile.isvalid = reshape(obj.mytile.isvalid, ...
                                 size(obj.mytile.data(:,:,1)));
               for chan = 1:c
                   tmp_img = obj.img(:,:,chan);
                   tmp_tile = obj.mytile.data(:,:,chan);
                   tmp_tile(obj.mytile.isvalid) = tmp_img(im_pts_linear);
                   obj.mytile.data(:,:,chan) = tmp_tile;
               end
               obj.mytile.origdata = obj.mytile.data;
               obj.mytile.origisvalid = obj.mytile.isvalid;
           end

           function obj = set_tile_on_plane(obj, p)
               obj.mytile_on_plane = obj.mytile.get_tile_on_plane(p);
               b = obj.mytile_on_plane.box;
               if(b.row_max-b.row_min < 1 || b.col_max-b.col_min < 1)
                   obj.useful = false;
               end
               obj.mytile_on_plane = ...
                   obj.mytile_on_plane.set_border_mask(p.blendpx);
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
               % My grid is 1 where it is filled
               % Their grid is 1 where it is filled
               box = obj.mytile_on_plane.box;
               grid(box.row_min:box.row_max,box.col_min:box.col_max) = true;                            
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

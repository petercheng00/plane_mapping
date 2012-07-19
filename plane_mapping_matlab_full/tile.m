classdef tile
    %tile Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        cropped_data;
        orig_data;
        cropped_box;
        orig_box;
        cropped_valid;
        orig_valid;
        sift_frames;
        sift_descr;
        border_mask;
    end
    
    methods
        % it's good to keep tile and tile_on_plane separate so we can apply
        % transformations to tile and crop tile_on_plane as needed without
        % losing data
        function tile_on_plane = get_tile_on_plane(obj, p)
            cut_top = max(0, 1 - obj.orig_box.row_min);
            cut_bot = max(0, obj.orig_box.row_max - p.height);
            cut_lft = max(0, 1 - obj.orig_box.col_min);
            cut_rht = max(0, obj.orig_box.col_max - p.width);
            tile_on_plane = tile();
            tile_on_plane.orig_box.row_min = obj.orig_box.row_min + cut_top;
            tile_on_plane.orig_box.row_max = obj.orig_box.row_max - cut_bot;
            tile_on_plane.orig_box.col_min = obj.orig_box.col_min + cut_lft;
            tile_on_plane.orig_box.col_max = obj.orig_box.col_max - cut_rht;
            tile_on_plane.orig_data = obj.orig_data(1+cut_top:end-cut_bot, ...
                1+cut_lft:end-cut_rht,:);
            
            tile_on_plane.orig_valid = obj.orig_valid(...
                1+cut_top:end-cut_bot, ...
                1+cut_lft:end-cut_rht);
            
            tile_on_plane = tile_on_plane.crop();
            %cut_top = max(0, 1 - obj.cropped_box.row_min);
            %cut_bot = max(0, obj.cropped_box.row_max - p.height);
            %cut_lft = max(0, 1 - obj.cropped_box.col_min);
            %cut_rht = max(0, obj.cropped_box.col_max - p.width);
            %tile_on_plane.cropped_box.row_min = obj.cropped_box.row_min + cut_top;
            %tile_on_plane.cropped_box.row_max = obj.cropped_box.row_max - cut_bot;
            %tile_on_plane.cropped_box.col_min = obj.cropped_box.col_min + cut_lft;
            %tile_on_plane.cropped_box.col_max = obj.cropped_box.col_max - cut_rht;
            %tile_on_plane.cropped_data = obj.cropped_data(1+cut_top:end-cut_bot, ...
            %    1+cut_lft:end-cut_rht,:);
            %
            %tile_on_plane.cropped_valid = obj.cropped_valid(...
            %    1+cut_top:end-cut_bot, ...
            %    1+cut_lft:end-cut_rht);
        end
        
        function obj = set_sift(obj)
            if prod(size(obj.cropped_data)) ~= 0
                [obj.sift_frames obj.sift_descr] = do_sift(uint8(obj.cropped_data), 0.001);
            end
        end
        
        function obj = crop(obj)
            % we want orig_data,orig_box, etc. to be a bounding rectangle
            % we want cropped_dat, cropped_box, etc. to be largest
            % rectangle inscribed within textured area
            if sum(sum(obj.orig_valid)) == 0
                return
            end
            
            temp_data = obj.orig_data;
            temp_valid = obj.orig_valid;
            temp_box = obj.orig_box;
            
            % first do orig cropping
            col_min = find(sum(obj.orig_valid,1)>0,1);
            col_max = find(sum(obj.orig_valid,1)>0,1,'last');
            row_min = find(sum(obj.orig_valid,2)>0,1);
            row_max = find(sum(obj.orig_valid,2)>0,1,'last');
            
            obj.orig_data = temp_data(row_min:row_max,col_min:col_max,:);
            obj.orig_valid = temp_valid(row_min:row_max,col_min:col_max,:);
            obj.orig_box.row_min = temp_box.row_min + row_min - 1;
            obj.orig_box.row_max = temp_box.row_min + row_max - 1;
            obj.orig_box.col_min = temp_box.col_min + col_min - 1;
            obj.orig_box.col_max = temp_box.col_min + col_max - 1;
            
            % now do cropped cropping
            while(1)
                dbstop if error
                if(row_max-row_min <= 0 || col_max-col_min <= 0)
                    break;
                end
                left_pct = sum(temp_valid(row_min:row_max,col_min))/(row_max-row_min+1);
                right_pct = sum(temp_valid(row_min:row_max,col_max))/(row_max-row_min+1);
                top_pct = sum(temp_valid(row_min,col_min:col_max))/(col_max-col_min+1);
                bot_pct = sum(temp_valid(row_max,col_min:col_max))/(col_max-col_min+1);
                min_pct = min([left_pct, right_pct, top_pct, bot_pct]);
                if(min_pct == 1)
                    break;
                end
                if(min_pct == left_pct) col_min = col_min+1; continue; end
                if(min_pct == right_pct) col_max = col_max-1; continue; end
                if(min_pct == top_pct) row_min = row_min+1; continue; end
                if(min_pct == bot_pct) row_max = row_max-1; continue; end
            end
            obj.cropped_data = temp_data(row_min:row_max, col_min:col_max,:);
            obj.cropped_valid = temp_valid(row_min:row_max, col_min:col_max);
            newbox.row_min = temp_box.row_min + row_min - 1;
            newbox.row_max = temp_box.row_min + row_max - 1;
            newbox.col_min = temp_box.col_min + col_min - 1;
            newbox.col_max = temp_box.col_min + col_max - 1;
            obj.cropped_box = newbox;
        end
       
        
        function obj = rotate(obj, angle)
            %obj.cropped_data = imrotate(obj.cropped_data, angle,'bilinear','crop');
            obj.orig_data = imrotate(obj.orig_data, angle,'bilinear','crop');
            %obj.cropped_valid = imrotate(obj.cropped_valid, angle, 'nearest', 'crop');
            obj.orig_valid = imrotate(obj.orig_valid, angle, 'nearest', 'crop');
            %assert(prod(size(obj.cropped_data(:,:,1))) == prod(size(obj.cropped_valid)));
            %assert(prod(size(obj.cropped_valid)) == (obj.cropped_box.row_max-obj.cropped_box.row_min+1) * ...
            %                                 (obj.cropped_box.col_max-obj.cropped_box.col_min+1));
        end
        
        function obj = set_border_mask(obj,b)
            obj.border_mask = obj.orig_valid;
            if(size(obj.border_mask,1) > 2*b && ...
                    size(obj.border_mask,2) > 2*b)
                obj.border_mask(b:end-b,b:end-b) = false;
            end
        end
    end
    
end


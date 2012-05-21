classdef tile
    %tile Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        data;
        origdata;
        box;
        origbox;
        isvalid;
        origisvalid;
        sift_frames;
        sift_descr;
        border_mask;
    end
    
    methods
        function tile_on_plane = get_tile_on_plane(obj, p)
            cut_top = max(0, 1 - obj.box.row_min);
            cut_bot = max(0, obj.box.row_max - p.height);
            cut_lft = max(0, 1 - obj.box.col_min);
            cut_rht = max(0, obj.box.col_max - p.width);
            tile_on_plane = tile();
            tile_on_plane.box.row_min = obj.box.row_min + cut_top;
            tile_on_plane.box.row_max = obj.box.row_max - cut_bot;
            tile_on_plane.box.col_min = obj.box.col_min + cut_lft;
            tile_on_plane.box.col_max = obj.box.col_max - cut_rht;
            tile_on_plane.data = obj.data(1+cut_top:end-cut_bot, ...
                1+cut_lft:end-cut_rht,:);
            
            tile_on_plane.isvalid = obj.isvalid(...
                1+cut_top:end-cut_bot, ...
                1+cut_lft:end-cut_rht);
            
            %orig values
            cut_top = max(0, 1 - obj.origbox.row_min);
            cut_bot = max(0, obj.origbox.row_max - p.height);
            cut_lft = max(0, 1 - obj.origbox.col_min);
            cut_rht = max(0, obj.origbox.col_max - p.width);
            
            tile_on_plane.origbox.row_min = obj.origbox.row_min + cut_top;
            tile_on_plane.origbox.row_max = obj.origbox.row_max - cut_bot;
            tile_on_plane.origbox.col_min = obj.origbox.col_min + cut_lft;
            tile_on_plane.origbox.col_max = obj.origbox.col_max - cut_rht;

            
            tile_on_plane.origdata = obj.origdata(1+cut_top:end-cut_bot, ...
                1+cut_lft:end-cut_rht,:);
            
            tile_on_plane.origisvalid = obj.origisvalid(...
                1+cut_top:end-cut_bot, ...
                1+cut_lft:end-cut_rht);

        end
        
        function obj = set_sift(obj)
            [obj.sift_frames obj.sift_descr] = do_sift(uint8(obj.data), 0.001);
        end
        
        function obj = crop(obj)
            % Determine where to crop
            binary_image = obj.isvalid;
            col_min = min(find(sum(binary_image,1)>0));
            col_max = max(find(sum(binary_image,1)>0));
            row_min = min(find(sum(binary_image,2)>0));
            row_max = max(find(sum(binary_image,2)>0));
            while(1)
                dbstop if error
                if(row_max-row_min <= 0 || col_max-col_min <= 0)
                    break;
                end
                left_pct = sum(binary_image(row_min:row_max,col_min))/(row_max-row_min+1);
                right_pct = sum(binary_image(row_min:row_max,col_max))/(row_max-row_min+1);
                top_pct = sum(binary_image(row_min,col_min:col_max))/(col_max-col_min+1);
                bot_pct = sum(binary_image(row_max,col_min:col_max))/(col_max-col_min+1);
                max_pct = max([left_pct, right_pct, top_pct, bot_pct]);
                min_pct = min([left_pct, right_pct, top_pct, bot_pct]);
                if(min_pct == 1)
                    break;
                end
                if(min_pct == left_pct) col_min = col_min+1; continue; end
                if(min_pct == right_pct) col_max = col_max-1; continue; end
                if(min_pct == top_pct) row_min = row_min+1; continue; end
                if(min_pct == bot_pct) row_max = row_max-1; continue; end
            end
            obj.data = obj.data(row_min:row_max, col_min:col_max,:);
            obj.isvalid = obj.isvalid(row_min:row_max, col_min:col_max);
            newbox.row_min = obj.box.row_min + row_min - 1;
            newbox.row_max = obj.box.row_min + row_max - 1;
            newbox.col_min = obj.box.col_min + col_min - 1;
            newbox.col_max = obj.box.col_min + col_max - 1;
            obj.box = newbox;
            
        end
        
        function obj = rotate(obj, angle)
            obj.data = imrotate(obj.data, angle,'bilinear','crop');
            obj.origdata = imrotate(obj.origdata, angle,'bilinear','crop');
            obj.isvalid = imrotate(obj.isvalid, angle, 'nearest', 'crop');
            obj.origisvalid = imrotate(obj.origisvalid, angle, 'nearest', 'crop');
            assert(prod(size(obj.data(:,:,1))) == prod(size(obj.isvalid)));
            assert(prod(size(obj.isvalid)) == (obj.box.row_max-obj.box.row_min+1) * ...
                                             (obj.box.col_max-obj.box.col_min+1));
        end
        
        function obj = set_border_mask(obj,b)
            obj.border_mask = obj.isvalid;
            if(size(obj.border_mask,1) > 2*b && ...
                    size(obj.border_mask,2) > 2*b)
                obj.border_mask(b:end-b,b:end-b) = false;
            end
        end
    end
    
end


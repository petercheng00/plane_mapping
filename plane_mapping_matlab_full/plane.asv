classdef plane < handle
    %Plane Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        height;
        width;
        base;
        side;
        down;
        normal;
        d;
        ratio;
        outimg;
        images = [];
        maxshift = 100;
        blendpx = 100;
        sortVertical = false;
    end
    
    methods
        function obj = load_images(obj, filenames, masks, rotations, t_cam2world, K)
            n = 1;
            for imgnum = 1:size(filenames,1)
                fprintf('Loading img number %d\tn=%d\n', imgnum,n);
                r = rotations{imgnum};
                t = t_cam2world(imgnum,:)';
                %cam_vec = [[0;0;0] r ...
                %    * [0;0;1000]] + repmat(t,1,2);
                %cam_vec = cam_vec(:,2) - cam_vec(:,1);
                %cam_vec = cam_vec / norm(cam_vec);
                %if(abs(cam_vec'*obj.normal) < 0.5)
                plane_to_cam = t - obj.base;
                if(plane_to_cam' * obj.normal) < 0.5
                    fprintf('Ignoring Bad Image\n');
                    continue
                end
                
                obj.images = [obj.images plane_img()];
                
                % Load the image and remove the part under the mask
                obj.images(n).img = imread(filenames{imgnum});
                obj.images(n).mask = imread(masks{imgnum}) > 0;
                % w is actually height, h is width, but the input images are sideways
                [w h chan] = size(obj.images(n).img);
                assert(chan==3)
                
                % Get the extrinsic matrix
                obj.images(n).r = r;
                obj.images(n).t = t;
                obj.images(n).K = K;
                n = n + 1;
            end
        end
        
        function obj = set_tiles(obj)
            for idx = 1:size(obj.images,2)
                fprintf('Projecting image %d\n', idx);
                obj.images(idx) = obj.images(idx).set_tile_and_rotate(obj);
                imshow(uint8(obj.images(idx).mytile.data));
                drawnow
            end
        end
        
        function obj = set_tiles_on_plane(obj)
            for idx = 1:size(obj.images,2)
                obj.images(idx) = obj.images(idx).set_tile_on_plane(obj);
            end
        end
        
        function obj = filter_useless(obj)
            useful = [];
            for idx = 1:size(obj.images,2)
                if obj.images(idx).useful
                    useful = [useful obj.images(idx)];
                end
            end
            obj.images = useful;
        end
        
        function obj = print_images(obj)
            for idx = 1:size(obj.images,2)
                fprintf('Printing image %d\n', idx);
                obj = obj.print_tile(obj.images(idx).mytile_on_plane);
                imshow(uint8(obj.outimg));
                drawnow
            end
        end
        
        function obj = print_greedy_area(obj)
            % Greedy approximation
            grid = false(obj.height,obj.width);
            cost = 0;
            while(1)
                contribution = [];
                for idx = 1:size(obj.images,2)
                    contribution(idx) = obj.images(idx).get_contribution(grid);
                end
                fprintf('contribution sum: %d\n', sum(contribution));
                if(sum(contribution) == 0)
                    break;
                else
                    maxidx = find(contribution == max(contribution),1);
                    keyboard
                    cost = cost +  obj.cost_of_tile(obj.images(maxidx).mytile_on_plane);
                    obj = obj.blend_tile(obj.images(maxidx).mytile_on_plane);
                    grid = obj.images(maxidx).update_logical(grid);
                end
            end
            fprintf('cost: %f\n', cost);
        end
        
        
        function obj = print_greedy_cost(obj)
            % First get the avg cost for each image
            node_total_cost = zeros(1,size(obj.images,2));
            node_cost_count = zeros(1,size(obj.images,2));
            node_avg_cost = zeros(1,size(obj.images,2));
            % For each starting image
            for idx1 = 1:size(obj.images,2)
                i1 = obj.images(idx1);
                if(~i1.useful) continue; end
                for idx2_i = 1:size(i1.overlap,2)
                    idx2 = i1.overlap(idx2_i);
                    i2 = obj.images(idx2);
                    obj.outimg = zeros(obj.height,obj.width,3);
                    obj = obj.print_tile(i1.mytile_on_plane);
                    cost = obj.cost_of_tile(i2.mytile_on_plane);

                    % End loop if it no longer overlaps
                    if(cost == Inf )
                        keyboard
                        fprintf('\n');
                        break
                    else
                        fprintf('Images %d to %d, cost=%f\n', idx1, idx2, cost)
                        node_total_cost(idx1) = node_total_cost(idx1) + cost;
                        node_total_cost(idx2) = node_total_cost(idx2) + cost;
                        node_cost_count(idx1) = node_cost_count(idx1)+1;
                        node_cost_count(idx2) = node_cost_count(idx2)+1;
                    end
                end
            end
            
            for idx = 1:size(obj.images,2)
                if (node_cost_count(idx) ~= 0)
                    node_avg_cost(idx) = node_total_cost(idx)/node_cost_count(idx);
                else
                    node_avg_cost(idx) = 0;
                end
            end
            
            [costs indices] = sort(node_avg_cost);
            grid = false(obj.height,obj.width);
            for idx_i = 1:size(indices,2)
                keyboard
                idx = indices(idx_i);
                if sum(obj.images(idx).get_contribution(grid)) == 0
                    keyboard
                    continue;
                end
                obj = obj.blend_localized_tile(obj.images(idx).mytile_on_plane);
                grid = obj.images(idx).update_logical(grid);
            end
        end
        
        
        
        % debug thing michael used
        function obj = print_greedy_cost_MA(obj)
            % Greedy approximation
            grid = false(obj.height,obj.width);
            cost = 0;
            while(1)
                contribution = [];
                costs = [];
                for idx = 1:size(obj.images,2)
                    costs(idx) = obj.cost_of_tile(obj.images(idx).mytile_on_plane);
                    contribution(idx) = obj.images(idx).get_contribution(grid);
                end
                fprintf('contribution sum: %d\n', sum(contribution));
                if(sum(contribution) == 0)
                    break;
                else            
                    maxidx = find(contribution == max(contribution),1);
                    cost = cost +  obj.cost_of_tile(obj.images(maxidx).mytile_on_plane);
                    obj = obj.blend_tile(obj.images(maxidx).mytile_on_plane);
                    grid = obj.images(maxidx).update_logical(grid);
                end
            end
            fprintf('cost: %f\n', cost);
        end
        
        function obj = print_dynprog(obj)
            % Generate cost DAG
            edge_cost = sparse(eye(size(obj.images,2)));
            node_total_cost = zeros(1,size(obj.images,2));
            node_cost_count = zeros(1,size(obj.images,2));
            node_avg_cost = zeros(1,size(obj.images,2));
            % For each starting image
            for idx1 = 1:size(obj.images,2)
                i1 = obj.images(idx1);
                if(~i1.useful) continue; end
                for idx2_i = 1:size(i1.overlap,2)
                    idx2 = i1.overlap(idx2_i);
                    if (idx1 == 1 || idx2 == size(obj.images,2))
                        edge_cost(idx1, idx2) = 1;
                        continue;
                    end
                    i2 = obj.images(idx2);
                    obj.outimg = zeros(obj.height,obj.width,3);
                    obj = obj.print_tile(i1.mytile_on_plane);
                    cost = obj.cost_of_tile(i2.mytile_on_plane);

                    % End loop if it no longer overlaps
                    if(cost == Inf )
                        keyboard
                        fprintf('\n');
                        break
                    else
                        fprintf('Images %d to %d, cost=%f\n', idx1, idx2, cost)
                        edge_cost(idx1,idx2) = cost;
                        node_total_cost(idx1) = node_total_cost(idx1) + cost;
                        node_total_cost(idx2) = node_total_cost(idx2) + cost;
                        node_cost_count(idx1) = node_cost_count(idx1)+1;
                        node_cost_count(idx2) = node_cost_count(idx2)+1;
                    end
                end
            end
            
            for idx = 1:size(obj.images,2)
                if (node_cost_count(idx) ~= 0)
                    node_avg_cost(idx) = node_total_cost(idx)/node_cost_count(idx);
                else
                    node_avg_cost(idx) = 0;
                end
            end
            % Ensure graph is connected
            total = sum(sum(edge_cost)) + sum(node_total_cost);
            for idx = 1:size(obj.images,2)-1
                if(edge_cost(idx,idx+1) == 0.0)
                    edge_cost(idx,idx+1) = total;
                end
            end
            %repeatedly solve shortest path problem
            valid_img = zeros(1,size(obj.images,2));
            grid = false(obj.height,obj.width);
            change_made = 1;
            iter = 0;
            while(change_made)
                iter = iter + 1;
                change_made = 0;
                % Solve shortest path
                memo = ones(1,size(obj.images,2)) .* Inf;
                path = zeros(1,size(obj.images,2));
                memo(1) = 0;

                % For each node
                for node = 2:size(obj.images,2)
                    % For each node coming in
                    for innode = 1:node-1
                        if(edge_cost(innode,node) ~= 0.0)
                            optimal_cost_in = memo(innode) + edge_cost(innode,node) + node_avg_cost(node);
                            if(optimal_cost_in < memo(node))
                                memo(node) = optimal_cost_in;
                                path(node) = innode;
                            end
                        end
                    end
                end
                % Backtrack through the array
                next_node = size(obj.images,2);
                for node = size(obj.images,2):-1:1
                    if(node == next_node)
                        if valid_img(node) == 0
                            newgrid = obj.images(node).update_logical(grid);
                            if sum(sum(newgrid ~= grid)) > 0
                                change_made = true;
                                grid = newgrid;
                                valid_img(node) = iter;
                            end
                        end
                        next_node = path(node);
                        %discourage picking this path next time
                        if next_node ~= 0
                            edge_cost(next_node, node) = total+1;
                        end
                    end
                end
            end
            obj.outimg = zeros(obj.height,obj.width,3);
            % remove the fake begin and end nodes
            
            obj.images = obj.images(2:size(obj.images,2)-1);
            valid_img = valid_img(2:size(valid_img,2)-1);
            % blend tiles only where we have holes.
            max_iter = max(valid_img);
            for iter = 1:max_iter
                for idx = 1:size(obj.images,2)
                    if(valid_img(idx) == iter)
                        obj = obj.blend_minimum_tile(obj.images(idx).mytile_on_plane);
                    end
                end
            end
            %for iter = max_iter:-1:1
            %    for idx = 1:size(obj.images,2)
            %        if(valid_img(idx) == iter)
            %            % Painter's algo
            %            obj = obj.blend_tile_painter(obj.images(idx).mytile_on_plane);
            %            keyboard
            %        end
            %    end
            %end
            if 1
                % use portions of chosen images that were previously cropped out
                % due to not being rectangular.
                for iter = 1:max_iter
                    if sum(sum(grid)) == (size(grid,1) * size(grid,2))
                        break;
                    end
                    for idx = 1:size(obj.images,2)
                        if (valid_img(idx) == iter)
                            obj = obj.blend_uncropped_tile(obj.images(idx).mytile_on_plane, grid);
                        end
                    end
                end
            end
            if 1
                % same as above, but use non-chosen images.
                if sum(sum(grid)) ~= (size(grid,1) * size(grid,2))
                    for idx = 1:size(obj.images,2)
                        if(~valid_img(idx))
                            obj = obj.blend_uncropped_tile(obj.images(idx).mytile_on_plane, grid);
                        end
                    end
                end
            end
        end
        
        function obj = fill_holes(obj)
            for i = round(size(obj.outimg,1)/2):-1:2
                start = 0;
                for j = 1:size(obj.outimg,2)
                    if sum(obj.outimg(i,j,:)) == 0 && start ==0
                        start = j;
                    elseif (sum(obj.outimg(i,j,:)) ~= 0 || (j == size(obj.outimg,2))) && start ~= 0
                        finish = j;
                        alpha = repmat(((start:finish)-start)/(finish-start),[1,1,3]);
                        bottomVal = mean(obj.outimg(i+30:i-1,start:finish,:),1);
                        if start == 1
                            leftVal = bottomVal;
                        else
                            leftStart = max(1,start-30);
                            leftVal = mean(obj.outimg(i,leftStart:start-1,:),2);
                            leftVal = repmat(leftVal,[1,(finish-start+1),1]);
                        end
                        if finish == size(obj.outimg,2)
                            rightVal = bottomVal;
                        else
                            rightFinish = min(size(obj.outimg,2),finish+30);
                            rightVal = mean(obj.outimg(i,finish+1:rightFinish,:),2);
                            rightVal = repmat(rightVal,[1,(finish-start+1),1]);
                        end
                        vals = (alpha.*rightVal + (1-alpha).*leftVal)/2 + bottomVal/2;
                        obj.outimg(i,start:finish,:) = vals;
                    end
                end
            end    
            for i = round(size(obj.outimg,1)/2):size(obj.outimg,1)-1
                start = 0;
                for j = 1:size(obj.outimg,2)
                    %if sum(obj.outimg(i+1,j,:)) == 0
                    %    samples = obj.outimg(max(1,i-10):i-1,j,:);
                    %    keyboard
                    %    %samples = [samples; obj.outimg(i,max(1,j-10):j-1,:)];
                    %    obj.outimg(i,j,:) = mean(samples);
                    if sum(obj.outimg(i,j,:)) == 0 && start ==0
                        start = j;
                    elseif (sum(obj.outimg(i,j,:)) ~= 0 || (j == size(obj.outimg,2))) && start ~= 0
                        finish = j;
                        alpha = repmat(((start:finish)-start)/(finish-start),[1,1,3]);
                        topVal = mean(obj.outimg(i-30:i-1,start:finish,:),1);
                        if start == 1
                            leftVal = topVal;
                        else
                            leftStart = max(1,start-30);
                            leftVal = mean(obj.outimg(i,leftStart:start-1,:),2);
                            leftVal = repmat(leftVal,[1,(finish-start+1),1]);
                        end
                        if finish == size(obj.outimg,2)
                            rightVal = topVal;
                        else
                            rightFinish = min(size(obj.outimg,2),finish+30);
                            rightVal = mean(obj.outimg(i,finish+1:rightFinish,:),2);
                            rightVal = repmat(rightVal,[1,(finish-start+1),1]);
                        end
                        vals = (alpha.*rightVal + (1-alpha).*leftVal)/2 + topVal/2;
                        obj.outimg(i,start:finish,:) = vals;
                    %    leftVal = mean(obj.outimg(i,max(1,start-10):start,:));
                    %    leftVal = repmat(leftVal,[1,finish-start+1]);
                    %    rightVal = mean(obj.outimg(i,finish:min(size(obj.outimg,2),finish+10),:));
                    %    rightVal = repmat(rightVal,[1,finish-start+1]);
                    %    k = start:finish;
                    %    topVal = (obj.outimg(max(size(obj.outimg,1),i-10),k,:));
                    %    alpha = (k-start)/(finish-start);
                    %    alpha = repmat(alpha,[1,1,3]);
                    %    obj.outimg(i,start:finish,:) = alpha .* rightVal + (1-alpha) .* leftVal;
                    %    start = 0;
                    end
                end
            end
        end
        
        function plane_pts = get_plane_pts(obj, box)
            [jj ii] = meshgrid(box.col_min:box.col_max, ...
                box.row_min:box.row_max);
            npoints = prod(size(ii));
            ivec = reshape(ii, [1,npoints]);
            jvec = reshape(jj, [1,npoints]);
            plane_pts = [ivec ; jvec];
        end
        
        
        function world_pts = get_world_pts(obj, plane_pts)
            npoints = size(plane_pts,2);
            world_pts = repmat(obj.base, [1,npoints]);
            world_pts = world_pts + ...
                repmat(plane_pts(1,:) / obj.height, [3,1]) .* ...
                repmat(obj.down, [1, npoints]);
            world_pts = world_pts + ...
                repmat(plane_pts(2,:) / obj.width, [3,1]) .* ...
                repmat(obj.side, [1, npoints]);
        end
        
        
        function closest_point = get_closest_plane_point(obj, cam_pt)
            world_pt = cam_pt - ...
                ((cam_pt - obj.base)'*obj.normal)*obj.normal;
            corner_vec = world_pt - obj.base;
            vert = norm(corner_vec'*(obj.down / norm(obj.down)))/norm(obj.down);
            horiz = norm(corner_vec'*(obj.side / norm(obj.side)))/norm(obj.side);
            closest_point = round([vert * obj.height ; horiz * obj.width]);
        end
        
        function obj = sort_images(obj)
            closest_points = [];
            for idx = 1:size(obj.images,2)
                closest_points(:,idx) = ...
                    obj.get_closest_plane_point(obj.images(idx).t);
            end
            vrange = max(closest_points(1,:)) - min(closest_points(1,:));
            hrange = max(closest_points(2,:)) - min(closest_points(2,:));
            I = [];
            if(vrange > hrange)
                obj.sortVertical = true;
                [pts I] = sort(closest_points(1,:));
            else
                [pts I] = sort(closest_points(2,:));
            end
            obj.images = obj.images(I);
        end
        
        function obj = sort_images2(obj)
            left = zeros(1,size(obj.images,2));
            top = zeros(1,size(obj.images,2));
            for idx = 1:size(obj.images,2)
                left(idx) = obj.images(idx).mytile_on_plane.box.col_min;
                top(idx) = obj.images(idx).mytile_on_plane.box.row_min;
            end
            hrange = max(left) - min(left);
            vrange = max(top) - min(top);
            I = [];
            if (vrange > hrange)
                obj.sortVertical = true;
                [pts I] = sort(top(1,:));
            else
                [pts I] = sort(left(1,:));
            end
            obj.images = obj.images(I);
        end
        
        function box = get_camera_box(obj, cam_pt, radius_in_cm)
            closest_point = obj.get_closest_plane_point(cam_pt);
            radius_pixels = obj.ratio * radius_in_cm;
            box.row_min = closest_point(1) - radius_pixels;
            box.row_max = closest_point(1) + radius_pixels;
            box.col_min = closest_point(2) - radius_pixels;
            box.col_max = closest_point(2) + radius_pixels;
        end
        
        function cost = cost_of_tile(obj, t)
            [h w c] = size(obj.outimg);
            box = t.box;
            existing_tile = obj.outimg(box.row_min:box.row_max,...
                                        box.col_min:box.col_max,:);
            existing_mask = sum(existing_tile,3) > 0;
            added_tile = t.data;
            added_mask = t.border_mask;
            ssd = 0;
            for chan = 1:c
                ssd = ssd + sum(sum((existing_tile(:,:,chan) - ...
                                    added_tile(:,:,chan)).^2 .* ...
                                    added_mask .* existing_mask));
            end
            cost = ssd;
        end
        
        function obj = print_tile(obj, t)
            box = t.box;
            [h w c] = size(obj.outimg);
            for chan = 1:c
                tmp_outimg = obj.outimg(box.row_min:box.row_max, ...
                    box.col_min:box.col_max,chan);
                tmp_tile = t.data(:,:,chan);
                tmp_outimg(t.isvalid) = ...
                    tmp_tile(t.isvalid);
                obj.outimg(box.row_min:box.row_max, ...
                    box.col_min:box.col_max,chan) = tmp_outimg;
            end
        end
        
        function obj = print_uncropped_tile(obj, t, grid)
            box = t.origbox;
            ii = 1;
            for i=box.row_min:box.row_max-1
                jj =1;
                for j=box.col_min:box.col_max-1
                    if(sum(obj.outimg(i,j,:),3)==0 && ...
                       sum(t.origdata(ii,jj,:))~=0 && sum(t.origdata(ii+1,jj+1,:)) ~= 0);
                        obj.outimg(i,j,:) = t.origdata(ii,jj,:);
                        grid(i,j) = 1;
                    end
                    jj = jj+1;
                end
                ii = ii+1;
            end
        end
        
        
        function obj = blend_uncropped_tile(obj, t, grid)
            box = t.origbox;
            ii = 1;
            for i=box.row_min:box.row_max
                jj =1;
                for j=box.col_min:box.col_max
                    if(sum(obj.outimg(i,j,:),3)==0 && ...
                       sum(t.origdata(ii,jj,:))~=0);
                       newVal = t.origdata(ii,jj,:);
                       count = 1;
                       % blend with surrounding pixels
                       for ix=i-5:i+5
                           for jx=j-5:j+5
                               if (ix >= box.row_min && ix <= box.row_max && jx >= box.col_min && jx <= box.col_max && sum(obj.outimg(ix,jx,:),3)~=0)
                                   newVal = newVal + obj.outimg(ix,jx,:);
                                   count = count + 1;
                               end
                           end
                       end
                       newVal = newVal / count;
                       obj.outimg(i,j,:) = newVal;
                       grid(i,j) = 1;
              
                    end
                    jj = jj+1;
                end
                ii = ii+1;
            end
        end
                    
        
        function obj = blend_tile(obj, t)
            box = t.box;
            ii = 1;
            for i=box.row_min:box.row_max
                jj = 1;
                for j=box.col_min:box.col_max
                    if(sum(obj.outimg(i,j,:),3)~=0)
                        mindist = min([ii,box.row_max-i,...
                            jj,box.col_max-j,...
                            obj.blendpx]);
                        alpha = mindist/obj.blendpx;
                        obj.outimg(i,j,:) = ...
                            t.data(ii,jj,:)*alpha +...
                            obj.outimg(i,j,:)*(1-alpha);
                    else
                        obj.outimg(i,j,:) = t.data(ii,jj,:);
                    end
                    jj = jj+1;
                end
                ii = ii+1;
            end
        end
        
        %placeholder, if we do this route in the future, simply don't do
        %blending if the edge goes to the edge of the plane.
        function obj = blend_tile_painter(obj, t)
            box = t.box;
            ii = 1;
            for i=box.row_min:box.row_max
                jj = 1;
                for j=box.col_min:box.col_max
                    if(sum(obj.outimg(i,j,:),3)~=0)
                        mindist = min([ii,box.row_max-i,...
                            jj,box.col_max-j,...
                            obj.blendpx]);
                        alpha = mindist/obj.blendpx;
                        obj.outimg(i,j,:) = ...
                            t.data(ii,jj,:)*alpha +...
                            obj.outimg(i,j,:)*(1-alpha);
                    else
                        obj.outimg(i,j,:) = t.data(ii,jj,:);
                    end
                    jj = jj+1;
                end
                ii = ii+1;
            end
        end
        
        
        function obj = blend_minimum_tile(obj, t)
            box = t.box;
            
            % Find largest (rectangular) hole within this box - this is
            % what we want to blend over
            % later need to check for multiple holes within this box
            
            
            % work with a local copy so we can track boxes and not deal
            % with 3 channels
            pixelGrid = sum(obj.outimg,3);
            
            foundHoles = [];
            
            currHole = box();
            currHole.row_min = 0;
            currHole.row_max = 0;
            currHole.col_min = 0;
            currHole.col_max = 0;
            
            for i=box.row_min:box.row_max
                for j = box.col_min:box.col_max
                    % we found an empty pixel, no col_min set yet
                    if((currHole.col_min == 0) && (pixelGrid(i,j) == 0))
                        currHole.row_min = i;
                        currHole.col_min = j;
                    end
                    % we found a filled pixel on the same row and we have col_min
                    % or we are at end of row without finding col_max
                    if ((currHole.col_min ~= 0) && (i == currHole.row_min) && ...
                            ((pixelGrid(i,j)~= 0) || (j == box.col_max)))
                        if pixelGrid(i,j)~=0
                            currHole.col_max = j-1;
                        else
                            currHole.col_max = j;
                        end
                        
                        
                        % Now see how many rows down this set up empty
                        % pixels goes
                        for ii = currHole.row_min:box.row_max
                            if (sum(pixelGrid(ii,currHole.col_min:currHole.col_max) ~= 0) ...
                                    || (ii == box.row_max))
                                if (sum(pixelGrid(ii,currHole.col_min:currHole.col_max) ~= 0))
                                    currHole.row_max = ii-1;
                                else
                                    currHole.row_max = ii;
                                end
                                break;
                            end
                        end
                        
                        % sanity check
                        if (currHole.row_min == 0 || currHole.row_max == 0 ...
                                || currHole.col_min == 0 || currHole.col_max == 0)
                            keyboard;
                        end
                        
                        % save hole, set up next one
                        pixelGrid(currHole.row_min:currHole.row_max,currHole.col_min:currHole.col_max) = ...
                            ones(currHole.row_max-currHole.row_min+1,currHole.col_max-currHole.col_min+1);
                        foundHoles = [foundHoles currHole];
                        currHole = box();
                        currHole.row_min = 0;
                        currHole.row_max = 0;
                        currHole.col_min = 0;
                        currHole.col_max = 0;
                    end
                end
            end
            
            patches = [];
            %here we expand the hole size to accomodate blending
            for h = 1:size(foundHoles,2)
                newPatch = box();
                newPatch.row_min = max(box.row_min,foundHoles(h).row_min-obj.blendpx);
                newPatch.row_max = min(box.row_max,foundHoles(h).row_max+obj.blendpx);
                newPatch.col_min = max(box.col_min,foundHoles(h).col_min-obj.blendpx);
                newPatch.col_max = min(box.col_max,foundHoles(h).col_max+obj.blendpx);
                patches = [patches newPatch];
            end
            % paste and blend now
            for h = 1:size(patches,2)
                patch = patches(h);
                hole = foundHoles(h);
                xLeft = hole.col_min - patch.col_min;
                xRight = patch.col_max - hole.col_max;
                yBottom = patch.row_max - hole.row_max;
                yTop = hole.row_min - patch.row_min;
                ii = patch.row_min-box.row_min+1;
                for i=patch.row_min:patch.row_max
                    jj = patch.col_min-box.col_min+1;
                    for j=patch.col_min:patch.col_max
                        if(sum(obj.outimg(i,j,:),3)~=0)
                            alphaX = -1;
                            alphaY = -1;
                            if xLeft>0 && j <= hole.col_min
                                xDist = hole.col_min - j;
                                alphaX = 1 - (xDist/xLeft);
                                xMax = xLeft;
                            elseif xRight>0 && j >= hole.col_max
                                xDist = j - hole.col_max;
                                alphaX = 1 - (xDist/xRight);
                                xMax = xRight;
                            end
                            if yTop>0 && i <= hole.row_min
                                yDist = hole.row_min - i;
                                alphaY = 1 - (yDist/yTop);
                                yMax = yTop;
                            elseif yBottom>0 && i >= hole.row_max
                                yDist = i - hole.row_max;
                                alphaY = 1 - (yDist/yBottom);
                                yMax = yBottom;
                            end
                            if (alphaX == -1 && alphaY == -1)
                                %a previous hole from this same image
                                %already filled this pixel, no problem
                            else
                                if (alphaX == -1)
                                    alpha = alphaY;
                                elseif (alphaY == -1)
                                    alpha = alphaX;
                                else
                                    diagMax = min([xMax,yMax]);
                                    diagDist = min([diagMax,sqrt(xDist^2 + yDist^2)]);
                                    alpha = 1 - diagDist/diagMax;
                                end
                                obj.outimg(i,j,:) = ...
                                    t.data(ii,jj,:)*alpha+...
                                    obj.outimg(i,j,:)*(1-alpha);
                            end
                        else
                            obj.outimg(i,j,:) = t.data(ii,jj,:);
                        end
                        jj = jj+1;
                    end
                    ii = ii+1;
                end
            end
        end
        
        
        function obj = set_sift(obj)
            for idx = 1:size(obj.images,2)
                fprintf('Getting SIFT descriptors for img: %d\n', idx);
                obj.images(idx) = obj.images(idx).set_sift();
            end
        end
        
        function obj = setup_DAG(obj)
            start_node = plane_img();
            end_node = plane_img();
            if obj.sortVertical
                start_node.mytile_on_plane.box.col_min = 1;
                start_node.mytile_on_plane.box.col_max = obj.width;
                start_node.mytile_on_plane.box.row_min = 1;
                start_node.mytile_on_plane.box.row_max = 2;
                end_node.mytile_on_plane.box.col_min = 1;
                end_node.mytile_on_plane.box.col_max = obj.width;
                end_node.mytile_on_plane.box.row_min = obj.height-1;
                end_node.mytile_on_plane.box.row_max = obj.height;
            else
                start_node.mytile_on_plane.box.col_min = 1;
                start_node.mytile_on_plane.box.col_max = 2;
                start_node.mytile_on_plane.box.row_min = 1;
                start_node.mytile_on_plane.box.row_max = obj.height;
                end_node.mytile_on_plane.box.col_min = obj.width - 1;
                end_node.mytile_on_plane.box.col_max = obj.width;
                end_node.mytile_on_plane.box.row_min = 1;
                end_node.mytile_on_plane.box.row_max = obj.height;
            end
            obj.images = [start_node obj.images end_node];
        end
        
        function obj = set_overlap(obj, maxoverlap)
            for idx1 = 1:size(obj.images,2)
                obj.images(idx1).overlap = [];
                limit = min(size(obj.images,2), idx1+maxoverlap);
                for idx2 = idx1+1:limit
                    %minimum band area for first and last node
                    blend = obj.blendpx;
                    if idx1 == 1 || idx2 == size(obj.images,2);
                        blend = 1;
                    end
                    b1 = obj.images(idx1).mytile_on_plane.box;
                    b2 = obj.images(idx2).mytile_on_plane.box;
                    if(box_overlap(b1, b2, blend))
                        obj.images(idx1).overlap = [obj.images(idx1).overlap ...
                            idx2];
                    end
                end
            end
        end
        
        function obj = fix_locations(obj)
            obj = obj.set_overlap(3);
            
            % Fix the positions with least squares
            xmat = zeros(1,size(obj.images,2));
            ymat = zeros(1,size(obj.images,2));
            xobs = [0]; yobs = [0]; w = [0];
            for idx1 = 1:size(obj.images,2)
                if(~obj.images(idx1).useful) continue; end
                s1 = obj.images(idx1);
                for idx2_i = 1:size(s1.overlap,2)
                    idx2 = s1.overlap(idx2_i);
                    if(~obj.images(idx2).useful) continue; end
                    s2 = obj.images(idx2);
                    fprintf('Matching images: %d and %d\n', idx1, idx2)
                    % Shift is the distance from one image to the next
                    [row_shift col_shift] = get_match_and_shift(s1.mytile_on_plane, s2.mytile_on_plane);
                    matches = true;
                    if(row_shift == 0 && col_shift == 0) matches = false; end
                    old_row_shift = s2.mytile_on_plane.box.row_min - s1.mytile_on_plane.box.row_min;
                    old_col_shift = s2.mytile_on_plane.box.col_min - s1.mytile_on_plane.box.col_min;
                    diff = abs(row_shift-old_row_shift) + abs(col_shift-old_col_shift);
                    if(diff < obj.maxshift && matches)
                        fprintf('row_shift: %f\told_row_shift: %f\n', row_shift, old_row_shift);
                        fprintf('col_shift: %f\told_col_shift: %f\n', col_shift, old_col_shift);
                        xmat(end,idx1) = -1; xmat(end,idx2) = 1;
                        ymat(end,idx1) = -1; ymat(end,idx2) = 1;
                        xmat(end+1,:) = 0; ymat(end+1,:) = 0;
                        xobs(end) = col_shift; xobs(end+1) = 0;
                        yobs(end) = row_shift; yobs(end+1) = 0;
                        w(end) = 1; w(end+1) = 0;
                    end
                    xmat(end,idx1) = -1; xmat(end,idx2) = 1;
                    ymat(end,idx1) = -1; ymat(end,idx2) = 1;
                    xmat(end+1,:) = 0; ymat(end+1,:) = 0;
                    xobs(end) = old_col_shift; xobs(end+1) = 0;
                    yobs(end) = old_row_shift; yobs(end+1) = 0;
                    w(end) = 0.01; w(end+1) = 0;
                end
                xmat(end,idx1) = 1;
                ymat(end,idx1) = 1;
                xmat(end+1,:) = 0; ymat(end+1,:) = 0;
                xobs(end) = s1.mytile_on_plane.box.col_min;  xobs(end+1) = 0;
                yobs(end) = s1.mytile_on_plane.box.row_min;  yobs(end+1) = 0;
                w(end) = 0.01; w(end+1) = 0;
            end
            
            xmat(end,1) = 1; ymat(end,1) = 1;
            xobs(end) = obj.images(1).mytile_on_plane.box.col_min;
            yobs(end) = obj.images(1).mytile_on_plane.box.row_min;
            w(end) = 0;
            
            % Solve using weighted least squares
            new_col_mins = lscov(xmat,xobs',w');
            new_row_mins = lscov(ymat,yobs',w');
            
            for idx = 1:size(obj.images,2)
                diff_col = round(new_col_mins(idx) - obj.images(idx).mytile_on_plane.box.col_min);
                diff_row = round(new_row_mins(idx) - obj.images(idx).mytile_on_plane.box.row_min);
                obj.images(idx).mytile.box.col_min = obj.images(idx).mytile.box.col_min + diff_col;
                obj.images(idx).mytile.box.col_max = obj.images(idx).mytile.box.col_max + diff_col;
                obj.images(idx).mytile.box.row_min = obj.images(idx).mytile.box.row_min + diff_row;
                obj.images(idx).mytile.box.row_max = obj.images(idx).mytile.box.row_max + diff_row;
                
                obj.images(idx).mytile.origbox.col_min = obj.images(idx).mytile.origbox.col_min + diff_col;
                obj.images(idx).mytile.origbox.col_max = obj.images(idx).mytile.origbox.col_max + diff_col;
                obj.images(idx).mytile.origbox.row_min = obj.images(idx).mytile.origbox.row_min + diff_row;
                obj.images(idx).mytile.origbox.row_max = obj.images(idx).mytile.origbox.row_max + diff_row;
            end
            obj = obj.set_tiles_on_plane();
        end
    end
    
end

